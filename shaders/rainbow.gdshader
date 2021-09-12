// https://glslsandbox.com/e#74785.0
shader_type canvas_item;
//precision mediump float;

//uniform float time;
uniform vec2 mouse;
//uniform vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;

uniform float PI = 3.14159265359;

uniform vec3 colorA = vec3(0.0);
uniform vec3 colorB = vec3(1.0);

void fragment() {
	vec2 st = FRAGCOORD.xy/(1.0 / SCREEN_PIXEL_SIZE).xy;
    vec3 color = vec3(0.0);

    vec3 pct = vec3(st.x);
    st.x+=0.250;
    
    st.x-=TIME/4.0;
    float amp = sin(TIME)+1.0;
    float freq = 2.0;

    pct.r = 0.5+sin((st.x+(freq*0./3.0))*PI*freq)/amp;
    pct.g = 0.5+sin((st.x+(freq*1./3.0))*PI*freq)/amp;
    pct.b = 0.5+sin((st.x+(freq*2./3.0))*PI*freq)/amp;

    color = mix(colorA, colorB, pct);
    color = mix(color*vec3(0.0), color*vec3(1.0), smoothstep(0.0, 1.0, st.y));

    COLOR = vec4(color,1.0);
}


