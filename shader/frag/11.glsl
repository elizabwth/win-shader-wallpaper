#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 resolution;

vec2 rotate(in vec2 v, in float a) {
    return vec2(cos(a)*v.x + sin(a)*v.y, -sin(a)*v.x + cos(a)*v.y);
}

float torus(in vec3 p, in vec2 t)
{
    vec2 q = abs(vec2(max(abs(p.x), abs(p.z))-t.x, p.y));
    return max(q.x, q.y)-t.y;
}

float trap(in vec3 p)
{
    //return abs(max(abs(p.z)-0.1, abs(p.x)-0.1))-0.01;
    //return length(max(abs(p.xy) - 0.05, 0.0));
    //return length(max(abs(p) - 0.35, 0.0));
    //return abs(length(p.xz)-0.2)-0.01;
    //return min(length(p.xz), min(length(p.yz), length(p.xy))) - 0.05;
    return abs(min(torus(vec3(p.x, mod(p.y,0.4)-0.2, p.z), vec2(0.1, 0.05)), max(abs(p.z)-0.05, abs(p.x)-0.05)))-0.005;
    return abs(min(torus(p, vec2(0.3, 0.05)), max(abs(p.z)-0.05, abs(p.x)-0.05)))-0.005;
}

float map(in vec3 p)
{
    float time2 = time+60.0;
    float cutout = dot(abs(p.yz),vec2(0.5))-0.035;
    //float road = max(abs(p.y-0.025), abs(p.z)-0.035);
    
    vec3 z = abs(1.0-mod(p,2.0));
    z.yz = rotate(z.yz, time2*0.05);

    float d = 999.0;
    float s = 1.0;
    for (float i = 0.0; i < 3.0; i++) {
        z.xz = rotate(z.xz, radians(i*10.0+time2));
        z.zy = rotate(z.yz, radians((i+1.0)*20.0+time2*1.1234));
        z = abs(1.0-mod(z+i/3.0,2.0));
        
        z = z*2.0 - 0.3;
        s *= 0.5;
        d = min(d, trap(z) * s);
    }
    return max(d, -cutout);
}

vec3 hsv(in float h, in float s, in float v) {
    return mix(vec3(1.0), clamp((abs(fract(h + vec3(3, 2, 1) / 3.0) * 6.0 - 3.0) - 1.0), 0.0 , 1.0), s) * v;
}

vec3 intersect(in vec3 rayOrigin, in vec3 rayDir)
{
    float time2 = time+60.0;
    float total_dist = 0.0;
    vec3 p = rayOrigin;
    float d = 1.0;
    float iter = 0.0;
    float mind = 3.14159+sin(time2*0.0)*0.0; // Move road from side to side slowly
    
    for (int i = 0; i < 59; i++)
    {       
        if (d < 0.001) continue;
        
        d = map(p);
        // This rotation causes the occasional distortion - like you would see from heat waves
        p += d*vec3(rayDir.x, rotate(rayDir.yz, sin(mind)));
        mind = min(mind, d);
        total_dist += d;
        iter++;
    }

    vec3 color = vec3(0.0);
    if (d < 0.001) {
        float x = (iter/59.0);
        float y = (d-0.01)/0.01/(59.0);
        float z = (0.01-d)/0.01/59.0;
        

            float q = 1.0-x-y*2.+z;
            color = hsv(q*0.2+0.85, 1.0-q*0.2, q);
    } 
        //color = hsv(d, 1.0, 1.0)*mind*45.0; // Background
    return color;
}

void main( void )
{
    float time2 = time+60.0;
    vec3 upDirection = vec3(0, -1, 0);
    vec3 cameraDir = vec3(1,0,0);
    vec3 cameraOrigin = vec3(time2*0.1, 0, 0);
    
    vec3 u = normalize(cross(upDirection, cameraOrigin));
    vec3 v = normalize(cross(cameraDir, u));
    vec2 screenPos = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    screenPos.x *= resolution.x / resolution.y;
    vec3 rayDir = normalize(u * screenPos.x + v * screenPos.y + cameraDir*(1.0-length(screenPos)*0.5));
    vec3 col = vec3( intersect(cameraOrigin, rayDir) );
    gl_FragColor = vec4(col,1.0);
} 