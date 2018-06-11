#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_derivatives : enable
vec2 hash22(vec2 p)
{
    p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(p)*43758.5453123);
}
float simplex_noise(vec2 p)
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - (i - (i.x + i.y) * K2);
    vec2 o = (a.x < a.y) ? vec2(0.0, 1.0) : vec2(1.0, 0.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hash22(i)), dot(b, hash22(i + o)), dot(c, hash22(i + 1.0)));
    return dot(vec3(70.0, 70.0, 70.0), n);
}
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main( void ) {

    vec2 pos = (( gl_FragCoord.xy / resolution.xy ) - vec2(0.5,0.5)) * 4.0;
    pos.x = pos.x*(resolution.x / resolution.y);
    float line = 0.0;
    vec3 Color = vec3(0.0);
    for(int i = 0; i < 50; i++)
    {
        line += (pos.x + 0.2 * sin(0.2 * time)) + (0.3 *simplex_noise(pos + 0.2 * time) + 1.0) * cos(2.5 * pos.y * (0.5 * sin(0.1 * time) + 3.0 + 0.03 * float(i)) + sin(0.1 * time) + 0.1 * float(i)) + pos.y * (2.0 + 0.5 * sin(0.2 * time));
        vec3 ColHSV = vec3(float(i) / 50.0, 1.0, 1.0);
        Color += 1.0 * hsv2rgb(ColHSV) / clamp(abs(line), 0.0, 100.0);
    }
    gl_FragColor = vec4(0.02 * Color / pow(abs(line), 0.5), 1.0) * max(4.0 - dot(pos, pos), 0.0);

}