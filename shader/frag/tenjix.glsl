// Tenjix

#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415926535897932384626433832795

uniform float time;
uniform vec2 resolution;
varying vec2 surfacePosition;

#define position (0.0+0.1*cos(time+gl_FragCoord.x)/(1.+cos(time/24.+dot(surfacePosition,surfacePosition)/24.)))
const float scale = 0.22;
const float intensity = 1.5;
const float speed = 0.2;

float band(vec2 pos, float amplitude, float frequency) {
	float wave = scale * amplitude * asin(sin(10.0 * PI * frequency * pos.x + time * speed)) / PI;
	float light = clamp(amplitude * frequency * 0.002, 0.001 + 0.001 / scale, 5.0) * scale / abs(wave - pos.y);
	return light;
}

void main( void ) {

	vec3 color = vec3(0.5, 0.5, 1.0);
	color = color == vec3(0.0)? vec3(0.5, 0.5, 1.0) : color;
	vec2 pos = (gl_FragCoord.xy / resolution.xy);
	pos.y += - 0.5 - position;

	float spectrum = 0.027;

	pos.y += band(pos, 0.1, 10.0);
	pos.x += band(-pos, 0.2, 8.0);
	pos.y -= band(-pos, 0.3, 5.0);
	pos.x -= band(pos, 0.5, 3.0);
	spectrum += band(-pos, 0.08, 1.5);
	spectrum += band(pos, 0.1, 1.0);

	gl_FragColor = vec4(color * spectrum, spectrum);

}