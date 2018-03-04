// "soft-min" test
// thanks to: http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015-sml.pdf

#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;


float soft_min(float a, float b, float r)
{
    float e = max(r - abs(a - b), 0.0);
    return min(a, b) - e*e*0.25 / r;
}

float hex( vec2 p, vec2 h )
{
	vec2 q = abs(p);
	return max(q.x-h.y,max(q.x+q.y*0.57735,q.y*1.1547)-h.x);
}

float sphere(vec3 p, float r)
{
	return length(p)-r;
}

float map(vec3 p)
{
	float h = -abs(p.y)+0.7;

	float scale = max(1.0, min(abs(p.y)*0.5, 1.2));
	vec2 grid = vec2(2.0, 2.9) * scale;
	float radius = 0. * scale;

	vec2 p1 = mod(p.xz, grid) - grid*vec2(0.5);
	float c1 = hex(p1, vec2(radius));

	vec2 p2 = mod(p.xz+grid*0.5, grid) - grid*vec2(0.5);
	float c2 = hex(p2, vec2(radius));
	
	float hexd = min(c1, c2);
	h += max(hexd, -0.005)*0.75;
	
	h = soft_min(h, sphere(p+vec3(sin(time*0.5), cos(time*0.6)*0.5, cos(time*0.5)), 0.9), 1.25);
	
	//return max(h, min(c1, c2));
	return h;
}


vec3 genNormal(vec3 p)
{
    const float d = 0.01;
    return normalize( vec3(
        map(p+vec3(  d,0.0,0.0))-map(p+vec3( -d,0.0,0.0)),
        map(p+vec3(0.0,  d,0.0))-map(p+vec3(0.0, -d,0.0)),
        map(p+vec3(0.0,0.0,  d))-map(p+vec3(0.0,0.0, -d)) ));
}

void main()
{
	float ct = time * 0.1;
    vec2 pos = (gl_FragCoord.xy*2.0 - resolution.xy) / resolution.y;
	vec3 camPos = vec3(5.0*cos(ct), 0.05, 5.0*sin(ct));
	vec3 camDir = normalize(vec3(-camPos.x, -0.5, -camPos.z));
	
	vec3 camUp  = normalize(vec3(0.4, 1.0, 0.0));
	vec3 camSide = cross(camDir, camUp);
    float focus = 1.8;

    vec3 rayDir = normalize(camSide*pos.x + camUp*pos.y + camDir*focus);	    
    vec3 ray = camPos;
    int march = 0;
    float d = 0.0;

    float total_d = 0.0;
    const int MAX_MARCH = 100;
    const float MAX_DIST = 100.0;
    for(int mi=0; mi<MAX_MARCH; ++mi) {
        d = map(ray);
        march=mi;
        total_d += d;
        ray += rayDir * d;
        if(d<0.001) {break; }
        if(total_d>MAX_DIST) {
            total_d = MAX_DIST;
            march = MAX_MARCH-1;
            break;
        }
    }
	
    float glow = 0.0;
    {
        const float s = 0.0075;
        vec3 p = ray;
        vec3 n1 = genNormal(ray);
        vec3 n2 = genNormal(ray+vec3(s, 0.0, 0.0));
        vec3 n3 = genNormal(ray+vec3(0.0, s, 0.0));
        glow = (1.0-abs(dot(camDir, n1)))*0.5;
        if(dot(n1, n2)<0.8 || dot(n1, n3)<0.8) {
            glow += 0.6;
        }
    }
    {
	vec3 p = ray;
        float grid1 = max(0.0, max((mod((p.x+p.y+p.z*2.0)-time*3.0, 5.0)-4.0)*1.5, 0.0) );
        float grid2 = max(0.0, max((mod((p.x+p.y*2.0+p.z)-time*2.0, 7.0)-6.0)*1.2, 0.0) );
        vec3 gp1 = abs(mod(p, vec3(0.24)));
        vec3 gp2 = abs(mod(p, vec3(0.32)));
        if(gp1.x<0.23 && gp1.z<0.23) {
            grid1 = 0.0;
        }
        if(gp2.y<0.31 && gp2.z<0.31) {
            grid2 = 0.0;
        }
        glow += grid1+grid2;
    }

    float fog = min(1.0, (3.0 / float(MAX_MARCH)) * float(march))*1.0;
    vec3  fog2 = 0.02 * vec3(1, 1, 1.5) * total_d;
    glow *= min(1.0, 4.0-(4.0 / float(MAX_MARCH-1)) * float(march));
    float scanline = 1.0;//mod(gl_FragCoord.y, 4.0) < 2.0 ? 0.7 : 1.0;
    gl_FragColor = vec4(vec3(0.15+glow*0.75, 0.15+glow*0.75, 0.2+glow)*fog + fog2, 1.0) * scanline;
}
