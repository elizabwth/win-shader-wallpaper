#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;



mat2 rotate(float a){
    float c=cos(a),s=sin(a);
    return mat2(c, s, -s, c);
}

float sc(vec3 p, float s) {
    p=abs(p);
    p=max(p,p.yzx);
    return min(p.x,min(p.y,p.z)) - s;
}

vec2 amod(vec2 p, float c) {
    float m = c/6.28;
    float a = mod(atan(p.x,p.y)-m*.5, m)-m*.5;
    return vec2(cos(a), sin(a)) * length(p);
}

void mo(inout vec2 p, vec2 d) {
    p.x = abs(p.x) - d.x;
    p.x = abs(p.x) - d.x;
    if(p.y>p.x)p=p.yx;
}

float glow = 0.;

float de(vec3 p) {
    vec3 q = p;
    p.xy *= rotate(time*.01);
    
    
    q.xy += vec2(sin(q.z*2.+1.)*.2+sin(q.z)*.05, sin(q.z)*.4);
    float c = length(max(abs(q+vec2(0,.05).xyx) - vec3(.01, .01, 1e6), 0.));
    
    p.xy *= rotate(p.z*.1);
    p.xy = amod(p.xy, 19.);//8.
    float d1 = 2.;
    p.z = mod(p.z-d1*.5, d1) - d1*.5;
    
    
    mo(p.xy, vec2(.1, .3));
    mo(p.xy, vec2(.8, .9));
    
    p.x = abs(p.x) - .8;

    p.xy *= rotate(.785);
    mo(p.xy, vec2(.2, .2));
    
    
    float d = sc(p, .1);
    d = min(d, c);
    glow+=.01/(.01+d*d);
    return d;
}

float raycast(vec3 ro, vec3 rd){
vec3 p;
float t=0.;
    
    for(int i=0;i<128;i+=1) {
        p=ro+rd*t;
        float d = de(p);
        if(t>30.) break;
        d = max(abs(d), .0004);
        t+=d*.5;
    }
    
    return t;
    
}


void main()
{
    vec2 uv = gl_FragCoord.xy/ resolution.xy -.5;
    
    uv.x*=resolution.x/resolution.y;
    
    vec3 ro=vec3(0,0,time*2.);
    vec3 rd=normalize(vec3(uv,1));
       
 
    float t = raycast(ro,rd);

    vec3 bg = vec3(.2, .1, .2);

    vec3 col = bg;
    if(t<=30.)
        col = mix(vec3(.9, .3, .3), bg, uv.x );

    col+=glow*.02;
    col = mix(col, bg, 1.-exp(-.1*t*t));
    
    gl_FragColor = vec4(col,1.0);
}