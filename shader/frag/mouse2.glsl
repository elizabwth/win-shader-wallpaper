#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float pi = atan(1.0) * 4.0;
const float zoom = 3.0;
// Structures

struct Box {
	vec2 center;
	vec2 relVertex;
};

struct CircularLight {
	vec2 position;
	float brightness;
};

// Program params

const vec3 ambient = vec3(0.1, 0.1, 0.25);
const vec3 boxColor = vec3(0.1, 0.1, 0.15);

// Functions

bool xnor(bool a, bool b) {
	return (a && b) || (!a && !b);
}

float toRad(float deg) {
	return deg * pi / 180.0;
}

vec2 rotate(vec2 v, float theta) {
	return vec2(v.x * cos(theta) - v.y * sin(theta), v.x * sin(theta) + v.y * cos(theta));
}

bool isInBox(vec2 position, Box box) {
	vec2 p = position - box.center;
	vec2 v = rotate(p, toRad(45.0) - atan(box.relVertex.y, box.relVertex.x));
	return max(abs(v.x), abs(v.y)) <= length(box.relVertex);
}

float unobstructedLightAt(vec2 position, CircularLight source) {
	float distance = length(source.position - position);
	return source.brightness / distance;
}

void boxObstructionRateAt(vec2 position, CircularLight source, Box box) {
	vec2 positionToLight = source.position - position;

}

vec2 absoluteToPosition(vec2 p) {
	return (p * 2.0 - resolution) / min(resolution.x, resolution.y) * zoom;
}

void main() {
	vec2 position = absoluteToPosition(gl_FragCoord.xy);
	vec2 mousePosition = (mouse - vec2(.5)) * 2.0 * zoom * (resolution / min(resolution.x, resolution.y));

	CircularLight fixedLight = CircularLight(vec2(0.9, 0.9), 0.2);
	CircularLight mouseLight = CircularLight(mousePosition, 0.1);
	Box centerBox = Box(vec2(0.0), rotate(vec2(0.0, 0.3), time));

	vec3 color = ambient;
	bool isPosInBox = isInBox(position, centerBox);
	if (isPosInBox) {
		color = boxColor;
		if (isInBox(fixedLight.position, centerBox)) color += unobstructedLightAt(position, fixedLight);
		if (isInBox(mouseLight.position, centerBox)) color += unobstructedLightAt(position, mouseLight);
	} else {
		color = ambient;
		if (!isInBox(fixedLight.position, centerBox)) color += unobstructedLightAt(position, fixedLight);
		if (!isInBox(mouseLight.position, centerBox)) color += unobstructedLightAt(position, mouseLight);
	}

	gl_FragColor = vec4(color, 1.0);
}