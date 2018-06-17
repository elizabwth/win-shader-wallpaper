/**
 * Whoever you are, you better be at Revision 2017 for Shader Showdown :)
 * LJ
 */
#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float smin(in float a, in float b, float k) {
	float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    	return mix( b, a, h ) - k*h*(1.0-h);
}

float tri(in float x) {
	return abs(fract(x)-.5);
}

float square(in float x) {
	return fract(x) > 0.5 ? 1.0 : 0.0;
}

vec3 tri3(in vec3 p) {
	return vec3( tri(p.z+tri(p.y*1.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));
}

vec3 sin3(vec3 p) {
	return abs(vec3(sin(p.z + sin(p.y)), sin(p.z + sin(p.x)), sin(p.y + sin(p.x)) ));
}

float sineNoise3d(in vec3 p, in float spd) {
	float z = 1.4;
	float rz = 0.;
	vec3 bp = p;
	for (float i=0.; i<=3.; i++ ) {
        	vec3 dg = sin3(bp*2.);
        	p += (dg+time*spd);

        	bp *= 1.8;
		z *= 1.5;
		p *= 1.2;
        	
        	rz += (tri(p.z+tri(p.x+tri(p.y))))/z;
        	bp += 0.14;
	}
	return rz;
}

float triNoise3d(in vec3 p, in float spd) {
	float z = 1.4;
	float rz = 0.;
	vec3 bp = p;
	for (float i=0.; i<=3.; i++ ) {
        	vec3 dg = tri3(bp*2.);
        	p += (dg+time*spd);

        	bp *= 1.8;
		z *= 1.5;
		p *= 1.2;
        	
        	rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
        	bp += 0.14;
	}
	return rz;
}

vec3 tri33(in vec3 x){return abs(x-floor(x)-.5);} 
float surfFunc(in vec3 p){
	return dot(tri33(p*0.5 + tri33(p*0.25).yzx), vec3(0.666));
}

vec2 path(in float z){ float s = sin(z/8.)*cos(z/12.); return vec2(s*12., 0.); }

float map(vec3 p) {
	
	/*
	float d = p.y;
	//vec3 bp = p + tri3(p * 3.0) * 0.1;
	float a = length(p - vec3(0.0, 0.25, 0.0)) - 0.5;
	a += sineNoise3d(p * 2.0, 0.01) * 0.05;
	d = min(d, a);
	return d;
	*/
	
	vec2 tun = abs(p.xy - path(p.z))*vec2(0.5, 0.7071);
	float n = 1.- max(tun.x, tun.y) + (0.5-surfFunc(p));
	float k = triNoise3d(p * 0.1, 0.1) * 0.15;
	return min(n - k*(sin(time)*0.5+0.5), p.y + 1.0 + k);
	
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(-1.0, 1.0) * 0.01;
    return normalize(
        e.xyy * map(p + e.xyy) +
        e.yxy * map(p + e.yxy) +
        e.yyx * map(p + e.yyx) +
        e.xxx * map(p + e.xxx)
    );
}

float shadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float t = mint;
    float res = 1.0;
    for(int i = 0; i < 30; i++) {
        if(t > maxt) continue;
        float h = map(ro + rd * t);
        t += h;
        res = min(res, k * h / t);
    }
    return res;
}

void main() {
	float time = time * 0.2;
/*	
  vec2 p = gl_FragCoord.xy / resolution;
  p = 2.0 * p - 1.0;
  p.x *= resolution.x / resolution.y;
  
  vec3 ro = vec3(0.0, 0.0, 5.0 + time);
  vec3 target = ro + vec3(0.0, 0.1, -0.5);
  target.xy += path(target.z);
  ro.xy += path(ro.z);
	
  vec3 cw = normalize(target - ro);
  vec3 cup = vec3(0.0, 1.0, 0.0);
  vec3 cu = normalize(cross(cw, cup));
  vec3 cv = normalize(cross(cu, cw));
  vec3 rd = normalize(p.x * cu + p.y * cv + 2.5 * cw);
*/	
	// Screen coordinates.
	vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5)/resolution.y;
	
	// Camera Setup.
	vec3 lookAt = vec3(0.0, 0.0, time*5.);  // "Look At" position.
	vec3 camPos = lookAt + vec3(0.0, 0.1, -0.5); // Camera position, doubling as the ray origin.
	
	// Light positioning. One is a little behind the camera, and the other is further down the tunnel.
	vec3 light_pos = camPos + vec3(0.0, 0.125, -0.125);// Put it a bit in front of the camera.
	vec3 light_pos2 = camPos + vec3(0.0, 0.0, 6.0);// Put it a bit in front of the camera.
	
	// Using the Z-value to perturb the XY-plane.
	// Sending the camera, "look at," and two light vectors down the tunnel. The "path" function is 
	// synchronized with the distance function. Change to "path2" to traverse the other tunnel.
	lookAt.xy += path(lookAt.z);
	camPos.xy += path(camPos.z);
	light_pos.xy += path(light_pos.z);
	light_pos2.xy += path(light_pos2.z);
	
	// Using the above to produce the unit ray-direction vector.
	float FOV = 3.141592/3.; // FOV - Field of view.
	vec3 forward = normalize(lookAt-camPos);
	vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
	vec3 up = cross(forward, right);
	
	// rd - Ray direction.
	vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
	
	// Swiveling the camera from left to right when turning corners.
	//rd.xy = rot2( path(lookAt.z).x/32. )*rd.xy;
		
	
  
  float t = 0.0;
  float e = 0.01;
  float h = e * 2.0;
  for(int i = 0; i < 60; i++) {
      if(h < e || t > 20.0) continue;
      h = map(camPos + rd * t);
      t += h;
  }
  
  float col = 0.0;
  vec3 color = vec3(0.0);
  if(h < e) {
    vec3 pos = camPos + rd * t;
    vec3 ligPos = camPos + vec3(0.0, 0.0, 0.0);
    vec3 lig = normalize(light_pos2 - pos);
    vec3 nor = calcNormal(pos);
    float dif = clamp(dot(nor, lig), 0.0, 1.0);
    float fre = 1.0 + dot(rd, nor);
    float spe = pow(clamp(dot(rd, reflect(lig, nor)), 0.0, 1.0), 32.0);
    float sh = shadow(pos, lig, 0.01, 20.0, 6.0) * 0.3 + 0.5;
    col = ((dif + spe) * sh + fre * 0.5);
  
    col *= pow(1.0 - t / 20.0, 2.0);
    color = mix(vec3(.23,.6,.5),vec3(.2,.134,.1)*1.3,step(-1.,pos.y))*col;//col * vec3(cos(1.0 + time * 0.2)*0.5 + 0.5, sin(0.8 + time)*0.5+0.5, 0.2);	  
  }
  gl_FragColor = vec4(color, 1.0);
}