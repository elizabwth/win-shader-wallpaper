#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_dervatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float pi = 3.14159265;

float normal(float val, float a, float b){
    float req = 0.0;
    req = (val - a) / (b - a);
    req = clamp(req, 0.0, 1.0);
    return req;
}

float wave(float index){
    return (sin(2.0 * pi * index + time) * 0.8 + 1.0) * resolution.y * 0.5;
}

void main(){
    vec2 uv = gl_FragCoord.xy;
    vec2 p = mouse * resolution;
    
    float gap = 40.0;
    p.x = floor(uv.x / gap + 0.5) * gap;
    p.y = wave(2.0 * p.x / resolution.x);
    
    float size = 6.0;
    float len = 0.0;
    len = length((p-uv));
    len = 1.0 - normal(len, size - 0.5, size + 0.5);
    
    p.x = floor(uv.x / gap + 0.5) * gap;
    p.y = floor(0.8 * uv.y / gap + 0.5) * gap / 0.8;
    
    size = 1.2;
    float len2 = 0.0;
    len2 = length((p-uv));
    len2 = 1.0 - normal(len2, size - 0.5, size + 0.5);
    
    len = clamp(len + len2, 0.0, 1.0);
    
    vec3 back = vec3(0.1, 0.1, 0.1);
    vec3 col1 = vec3(0.0, 0.8, 0.8);
    vec3 col2 = vec3(0.4, 0.8, 0.4);
    
    vec3 col_ = col1 * (1.0 - uv.x / resolution.x) + col2 * (uv.x / resolution.x);
    vec3 col = col_ * len + back * (1.0 - len);
    
    gl_FragColor = vec4(col, 1.0);
}