//pastel psx/dreamcast thingy
// @samloeschen

#ifdef GL_ES
precision mediump float;
#endif

#define M_PI 3.1415926535897932384626433832795

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;


// 2D Random
float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d   
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners porcentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

bool boxtest (in vec2 p, in vec2 square, in float w) {
    return p.x - w < square.x && p.x + w > square.x && p.y - w < square.y && p.y + w > square.y;
}

vec3 palette (in float t) {
    vec3 a = vec3(0.93,0.43,0.76);
    vec3 b = vec3(0.90,0.31,0.24);
    vec3 c = vec3(0.41,0.93,1.0);
    vec3 d = vec3(0,0.44,0.32);
    return a + b*cos( 2.0*M_PI*(c*t+d) );
}

vec3 drawSquare (in vec2 p, in vec2 square, in vec3 setting) {
    if(boxtest(p, square, setting.x) && !(boxtest(p, square, setting.x - setting.y))) 
        return palette(setting.z / 70.0 + time * 0.1);

    return vec3(0.0);
}

void main (void) {
    vec2 uv = (gl_FragCoord.xy / resolution.xy);
    vec2 aspect = resolution.xy / min(resolution.x, resolution.y);
    vec2 center = vec2(0.5);
    vec2 pos = uv - center;
    float horizon = 0.03*cos(time); //lil motion here
    float fov = -0.5; //if we negate fov the box has a better palette relationship with the planes

    vec3 p = vec3(pos.x, fov, pos.y - horizon);
    float scroll = (time * -sign(p.z));
    float bump = noise((vec2(p.x + 100., p.y) * 20.)) * 0.1;
    vec2 s = vec2(p.x/p.z, p.y/p.z + bump + scroll) * 0.1; //actual plane position

    bool grid = (fract(s.y / 0.02) > 0.95) || (fract(s.x / 0.02) > 0.95);
    vec3 gridColor = (mix(palette(s.y + bump * 0.5), vec3(1.0), float(grid)));
    gridColor = mix(gridColor, vec3(1.0), 0.3); //slight desaturate and boost
    float fog = pow(sin(uv.y * M_PI), 5.);
    vec3 color = mix(gridColor, vec3(1.0), fog);

    float a = sin(time) * 0.6; //box angle
    mat2 rot = mat2(cos(a), -sin(a), sin(a), cos(a));
    pos = uv * aspect * rot; 
    center *= aspect * rot;
    
    for(int i = 0; i < 50; i++) {
        vec3 d = drawSquare(pos, center + vec2(sin(float(i) / 10.0 + time) / 4.0, 0.0), vec3(0.0 + sin(float(i) / 200.0), 0.01 , float(i)));
        if(d.x > 0.) color = mix(d, vec3(1.0), 0.3); //slight desaturate and boost
    }
    gl_FragColor = vec4(color, 1.0);
}
