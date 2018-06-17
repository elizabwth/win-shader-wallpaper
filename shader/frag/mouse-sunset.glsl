// sunset - valery.sntx@gmail.com 02/2018

// https://files.scene.org/view/parties/2017/tokyodemofest17/glsl_graphics_compo/ocean.zip

#ifdef GL_ES
precision highp float;
#endif

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define M_PI (3.14159265358979)
#define GRAVITY (9.80665)
#define EPS (1e-3)
#define USE_ROUGHNESS_TEXTURE
#define WAVENUM (32)

const float kSensorWidth = 36e-3;
const float kSensorDist = 18e-3;

const vec2 wind = vec2(45.0, 14.0);
const float kOceanScale = 0.0;

uniform sampler2D texture;

struct Ray
{
vec3 o;
    vec3 dir;
};

struct HitInfo
{
	vec3 pos;
    vec3 normal;
    float dist;
    Ray ray;
};

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float rand(vec3 n)
{
    return fract(sin(dot(n, vec3(12.9898, 4.1414, 5.87924))) * 43758.5453);
}

float Noise2D(vec2 p)
{
    vec2 e = vec2(0.0, 5.0);
    vec2 mn = floor(p);
    vec2 xy = fract(p);

    float val = mix(
        mix(rand(mn + e.xx), rand(mn + e.yx), xy.x),
        mix(rand(mn + e.xy), rand(mn + e.yy), xy.x),
        xy.y
    );

    val = val * val * (3.0 - 2.0 * val);
    return val;
}

float Noise3D(vec3 p)
{
    vec2 e = vec2(0.0, 1.0);
    vec3 i = floor(p);
    vec3 f = fract(p);

    float x0 = mix(rand(i + e.xxx), rand(i + e.yxx), f.x);
    float x1 = mix(rand(i + e.xyx), rand(i + e.yyx), f.x);
    float x2 = mix(rand(i + e.xxy), rand(i + e.yxy), f.x);
    float x3 = mix(rand(i + e.xyy), rand(i + e.yyy), f.x);

    float y0 = mix(x0, x1, f.y);
    float y1 = mix(x2, x3, f.z);

    float val = mix(y0, y1, f.z);

    val = val *  (3.0 * val);
    return val;
}

vec3 godrays(
    float density,
    float weight,
    float decay,
    float exposure,
    int numSamples,
    vec2 screenSpaceLightPos,
    vec2 uv
    ) {

    vec3 fragColor = vec3(0.0,0.0,0.0);

	vec2 deltaTextCoord = vec2( uv - screenSpaceLightPos.xy );

	vec2 textCoo = uv.xy ;
	deltaTextCoord *= (1.0 /  float(numSamples)) * density;
	float illuminationDecay = 1.0;


	for(int i=0; i < 100 ; i++){

	    if(numSamples < i) {
            break;
	    }

		textCoo -= deltaTextCoord;
		vec3 samp = vec3(uv.xy,  Noise3D(vec3(textCoo.xy, exposure)));
			samp /= illuminationDecay * weight;
		fragColor *=  normalize(samp);
		illuminationDecay *= decay;
	}

	fragColor += 0.01 / exposure;

    return fragColor;


}


float SmoothNoise(vec3 p)
{
    float amp = 0.5;
    float freq = 1.0;
    float val = 0.0;

    for (int i = 0; i < 4; i++)
    {
        amp *= 0.5;
        val += amp * Noise3D(freq * 45.0 * p - float(i) * 1.7179);
        freq *= p.y / 10.0 * p.x;
    }

    return val;
}

float Pow5(float x)
{
    return (x * x) * (x * x) * x;
}

// GGX Distribution
// Ref: https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.pdf
float DTerm(vec3 l, float HDotN, float alpha2)
{
    float HDotN2 = HDotN * HDotN;
    float x = (1.0 - (1.0 - alpha2) * HDotN2);
    float D = alpha2 / (M_PI * x * l.z);
    return D;
}

// Smith Joint Masking-Shadowing Function
// Ref: https://hal.inria.fr/hal-00942452v1/document
float GTerm(float LDotN, float VDotN, float alpha2)
{
    float tanThetaLN2 = 1.0 / (LDotN * LDotN) - 1.0;
    float tanThetaVN2 = 1.0 / (VDotN * VDotN) - 1.0;

    float lambdaL = 0.5 * sqrt(1.0 + alpha2 * tanThetaLN2) - 0.5;
    float lambdaV = 0.5 * sqrt(1.0 + alpha2 * tanThetaVN2) - 0.5;

    return 1.0 / (1.0 + lambdaL + lambdaV);
}

vec3 PostEffects(vec3 rgb, vec2 xy)
{
	// Gamma first...
	rgb = pow(rgb, vec3(0.45));
	
	// Then...
	#define CONTRAST 1.4
	#define SATURATION 1.4
	#define BRIGHTNESS 1.2
	rgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb*BRIGHTNESS)), rgb*BRIGHTNESS, SATURATION), CONTRAST);
	// Vignette...
	rgb *= .4+0.5*pow(40.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2 );	
	return rgb;
}

// Schlick approx
// Ref: https://en.wikipedia.org/wiki/Schlick's_approximation
float FTerm(float LDotH, float f0)
{
    return f0 + (1.0 - f0) * Pow5(1.0 - LDotH);
}

float TorranceSparrowBRDF(vec3 v, vec3 l, HitInfo hit, float roughness)
{
    vec3 h = normalize(l + v);

    float VDotN = dot(v, hit.normal);
    float LDotN = dot(l, hit.normal);
    float HDotN = dot(h, hit.normal);
    float LDotH = dot(l, h);

    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;

    float D = DTerm(l, HDotN, alpha2);
    float G = GTerm(LDotN, VDotN, alpha2);
    float F = FTerm(LDotH, 0.95);
    return (D * G * F) / (4.0 * abs(VDotN) * abs(LDotN));
}

struct OceanInfo
{
    float height;
    vec3 normal;
};

#define EULER 2.7182818284590452353602874
// its from here https://www.shadertoy.com/view/4dBcRD
float wave(vec2 uv, vec2 emitter, float speed, float phase, float timeshift){
	float dst = distance(uv, emitter);
	return pow(EULER, sin(dst * phase - (time + timeshift) * speed)) / EULER;
}
vec2 wavedrag(vec2 uv, vec2 emitter){
	return normalize(uv - emitter);
}

#define DRAG_MULT 4.0

float getwaves(vec2 position){
    position *= 0.1;
	float iter = 0.0;
    float phase = 6.0;
    float speed = 2.0;
    float weight = 1.0;
    float w = 0.0;
    float ws = 0.0;
    for(int i=0;i<64;i++){
        vec2 p = vec2(sin(iter), cos(iter)) * 30.0;
        float res = wave(position, p, speed, phase, 0.0);
        float res2 = wave(position, p, speed, phase, 0.006);
        position -= wavedrag(position, p) * (res - res2) * weight * DRAG_MULT;
        w += res * weight;
        iter += 12.0;
        ws += weight;
        weight = mix(weight, 0.0, 0.2);
        phase *= 1.2;
        speed *= 1.02;
    }
    return w / ws;
}
float OceanHeight(vec2 position)
{
	position *= 10.0;
    return getwaves(position) * 0.1;
}

vec3 OceanNormal(vec2 p, vec3 camPos)
{
    vec2 e = vec2(0, 1.0 * EPS);
    float l = 20.0 * distance(vec3(p.x, 0.0, p.y), camPos);
    e.y *= l;

    float hx = OceanHeight(p + e.yx) - OceanHeight(p - e.yx);
    float hz = OceanHeight(p + e.xy) - OceanHeight(p - e.xy);
    return normalize(vec3(-hx, 2.0 * e.y, -hz));
}

bool RayMarchOcean(Ray ray, out HitInfo hit) {
    vec3 rayPos = ray.o;
    float dl = rayPos.y / abs(ray.dir.y);
    rayPos += ray.dir * dl;
    hit.pos = rayPos;
    hit.normal = OceanNormal(rayPos.xz, ray.o * 2.0);
    hit.dist = length(rayPos - ray.o);
    return true;
}

#define CLOUD_ITER (32)
vec3 RayMarchCloud(Ray ray, vec3 sunDir, vec3 bgColor)
{
    float cloudHeight = 100.0;

    vec3 rayPos = ray.o;
    rayPos += ray.dir * (cloudHeight - rayPos.y) / ray.dir.y;

    float c = clamp(dot(sunDir, -ray.dir), 0.0, 1.0);

    float dl = 1.0;
    float scatter = 0.0;
    vec3 t = bgColor;
    for(int i = 0; i < CLOUD_ITER; i++) {
        rayPos += dl * ray.dir;
        float dens = SmoothNoise(vec3(0.01, 0.005, 0.05) * rayPos - vec3(0, 0.2 * time, 1.0 * time)) *
            smoothstep(0.0, 1.0, SmoothNoise(vec3(0.003, 0.001, 0.005) * rayPos)) * smoothstep(cloudHeight, cloudHeight + 1.0, rayPos.y);
        t -= 0.01 * t * dens * dl;
        t += 0.02 * dens * dl;
	}
    return t;
}

vec3 BGColor(vec3 dir, vec3 sunDir) {
    vec3 color = vec3(0);

    color += mix(
        vec3(0.094, 0.2266, 0.3711),
        vec3(0.988, 0.6953, 0.3805),
       	clamp(0.0, 1.0, dot(sunDir, dir) * dot(sunDir, dir)) * smoothstep(-0.25, 0.1, sunDir.y)
    );

    dir.x += 0.01 * sin(312.47 * dir.y + time) * exp(-40.0 * dir.y);
    dir = normalize(dir);

    color += smoothstep(0.995, 1.0, dot(sunDir, dir));
	return color;
}

void main( void )
{
	vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
	float aspect = resolution.y / resolution.x;

    // Camera settings
	vec3 camPos = vec3(0, 0.5 + 0.1 * (0.5 * (2.0 * 1.) + 0.5),  0.0);
    vec3 camDir = vec3(0, 0.002 * ((vec2(time, 0.1).y) - 0.5), -1);
	vec3 camTarget = vec3(camPos + camDir);

    vec3 up = (vec3(0., 1.0, 110.0));
	vec3 camForward = normalize(camTarget - camPos);
	vec3 camRight = cross(camForward, up);
	vec3 camUp = cross(camRight, camForward);
    Ray ray;
    ray.o = camPos;
    ray.dir = normalize(
        kSensorDist * camForward +
        kSensorWidth * 0.5 * uv.x * camRight +
        kSensorWidth * 0.5 * aspect * uv.y * camUp
    );

    vec3 sunDir = normalize(vec3(0, -0.1 + 0.2 * mouse.x, -1));

    vec3 color = vec3(0);
	HitInfo hit;
    float l = 1.0;
    if (ray.dir.y < 0.0 && RayMarchOcean(ray, hit)) {
        vec3 baseColor = vec3(0.0, 0.2648, 0.4421) * dot(-ray.dir, vec3(0, 1, 0));

        vec3 refDir = reflect(ray.dir, hit.normal);
        refDir.y = abs(refDir.y);
        l = (0.0 - camPos.y) / ray.dir.y;
         float roughness = clamp(0.0, 1.0, 1.0 - 1.0 / (0.1 * l));
       float brdf = TorranceSparrowBRDF(-ray.dir, sunDir, hit, roughness) * clamp(dot(sunDir, hit.normal), 0.1, 5.0);
          // float brdf2 = TorranceSparrowBRDF(-ray.dir, refDir, hit, roughness) * clamp(dot(refDir, hit.normal), 0.0, 1.0);

        color = baseColor + BGColor(refDir, sunDir) * FTerm(dot(refDir, hit.normal), brdf);
    } else {
        vec3 bgColor = BGColor(ray.dir, sunDir);
        if (ray.dir.y >= .0)
        {
            color += RayMarchCloud(ray, sunDir, bgColor);
        }
        l = (10.0 
	     + camPos.z) / ray.dir.y;
    }

	
  vec3 cc = godrays(6.5,
    1.1,
    1.14,
    1.5,
    50,

    vec2(camPos.x,camPos.y),
    uv
    );
	
    color = mix(color, BGColor(ray.dir, -sunDir), 1.0 - exp(-0.01 * l));
    color += smoothstep(0.0, 55.0, -cc);
	color+=PostEffects(color*cc, camPos.xz);
  
	gl_FragColor = vec4(color,1);
}
