// https://glslsandbox.com/e#67567.0
shader_type canvas_item;
/*
 * Original shader from: https://www.shadertoy.com/view/tdjXDd
 */

//uniform float time;
//uniform vec2 resolution;

uniform float PI = 3.1415926;
uniform float TAU = 6.2831852;
const vec3 BLACK_COL = vec3(24,32,38)/255.0;

float rand1(float p)
{
	return fract(sin(p* 78.233)* 43758.5453);
} 

vec4 hue(float h) { 
	return clamp( abs( fract(h + vec4(3,2,1,0)/3.) * 6. - 3.) -1. , 0., 1.);
}

void fragment(){
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = (FRAGCOORD.xy-resolution.xy*0.5)/resolution.y;

    float SIZE = 4. + cos(TIME*0.2)*0.5;
    float r = length(uv) * SIZE;
    r*=10.0;
    float id = ceil(r);
    float s = mod(id, 2.)*2. - 1.; // Direction
    float a = fract(atan(uv.y, uv.x)/TAU + s*(TIME*(rand1(id+400.)*0.5+0.5)*0.2 + id*0.2));
    float inRange = step(3.,id); // Don's draw center arcs    
    float sm = (1./resolution.y * 20.* SIZE);    
    
    inRange *= smoothstep(.0, sm, fract(r)) * smoothstep(1.0, 1.0 - sm, fract(r));
    float arcLength =  (rand1(id)*0.25 + 0.25);
    
    sm = (sqrt(SIZE)*(1./resolution.y * 5. / id));
    inRange *= smoothstep(arcLength, arcLength + sm, a) * smoothstep(1.0, 1. - sm, a);
        
    vec3 col = hue(rand1(id)).rgb;
    
    col = mix(BLACK_COL, col, inRange);
    
    COLOR = vec4(col,1.0);
}
// --------[ Original ShaderToy ends here ]---------- //

//void main(void)
//{
//    mainImage(gl_FragColor, gl_FragCoord.xy);
//}
