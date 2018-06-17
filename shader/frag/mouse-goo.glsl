#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_derivatives : enable

// Rising stones by WAHa.06x36^SVatG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

vec4 snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

    
// Mix final noise value
vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    vec4 m2 = m * m;
    vec4 m4 = m2 * m2;

    vec4 pdotx = vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3));

    vec4 temp = m2 * m * pdotx;
    vec3 grad = -8.0 * (temp.x * x0 + temp.y * x1 + temp.z * x2 + temp.w * x3);
    grad += m4.x * p0 + m4.y * p1 + m4.z * p2 + m4.w * p3;
 
    return 42.0 * vec4(grad, dot(m4, pdotx));
}

vec3 getSkyColor(vec3 e) {
    float y = e.y;
    vec4 r = snoise(150.0 * e);
    y+=r.w*0.01-r.y*0.005;
    y = atan(2.0*y);
    return mix(vec3(1.0,1.0,0.7), vec3(0.5,0.7,0.4), clamp(y + 1.0, 0.0, 1.0))+
        mix(vec3(0.0), -vec3(0.5,0.7,0.4), clamp(y, 0.0, 1.0));
}

mat3 fromEuler(vec3 ang) {
    vec2 a1 = vec2(sin(ang.x), cos(ang.x));
    vec2 a2 = vec2(sin(ang.y), cos(ang.y));
    vec2 a3 = vec2(sin(ang.z), cos(ang.z));
    return mat3(
        vec3(a1.y * a3.y + a1.x * a2.x * a3.x, a1.y * a2.x * a3.x + a3.y * a1.x, -a2.y * a3.x),
        vec3(-a2.y * a1.x, a1.y * a2.y, a2.x),
        vec3(a3.y * a1.x * a2.x + a1.y * a3.x, a1.x * a3.x - a1.y * a3.y * a2.x, a2.y * a3.y)
    );
}

float distance(vec3 p) {
    return (snoise(p + vec3(0.0, -time * 0.1, 0.0)).w + length(p) * 0.3) * 0.3;
}

void main( void ) {
    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
        
    vec3 pos = vec3(0.0,0.0, -4.0);
    vec3 ang = vec3( 0.0, -(mouse.y - 0.5) * 3.14159265 * 1.0, mouse.x * 3.1415926535 * 2.0);
    vec3 dir = normalize(vec3(p.xy, -2.0 + length(p) * 0.15)) * fromEuler(ang);
    
    vec3 sky = getSkyColor(dir);

    vec3 colour = pow(clamp(sky, 0.0, 1.0),vec3(0.75));
    
    for (int i = 0; i< 256; i++) {
        float dist = distance(pos);
        if (dist < 0.001) {
            float e = 0.01;
            vec3 n = normalize(vec3(dist - distance(pos - vec3(e, 0, 0)), dist - distance(pos - vec3(0, e, 0)), dist - distance(pos - vec3(0, 0, e))));
            vec4 t = snoise(70.0 * (pos + vec3(0.0, -time * 0.1, 0.0)));
            colour = vec3(1.0 - 0.75 * float(i) / 256.0) * (1.0 + 0.3 * -n.y + 0.005 * t.y) * vec3(0.9, 1.0, 0.8);
            break;
        }
        if (length(pos) > 30.0) break;
        pos += dir * dist;
    }
    
    gl_FragColor = vec4(colour, 1.0);
}
