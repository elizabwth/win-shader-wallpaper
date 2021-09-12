// https://glslsandbox.com/e#74688.5
shader_type canvas_item;

uniform float EPS = 0.01;

//uniform float time;
uniform vec2 mouse;
//uniform vec2 resolution;

vec2 rot2d(vec2 pos, float rad) {
  return vec2(
              pos.x * cos(rad) - pos.y * sin(rad),
              pos.x * sin(rad) + pos.y * cos(rad)
              );
}

float min4(float a, float b, float c, float d) {
  return min(a, min(b, min(c, d)));
}

float tube(vec2 pos, float width) {
  return length(pos) - width;
}

vec2 rep2(vec2 pos, float interval) {
  return mod(pos, interval) - interval * 0.5;
}

vec3 rep3(vec3 pos, float interval){
  return mod(pos, interval) - interval * .5;
}

float sphere(vec3 pos, float size) {
  return length(pos) - size;
}

float tw(float time)
{
	return sin(time) * 0.5 + 0.5;
}

float dist(vec3 pos) {
  return min4(
              sphere(rep3(pos, 5.0), 1.0),
              10000.0,//tube(rep2(pos.xz, 8.0), .5),
              10000.0,//tube(rep2(pos.yx, 8.0), .5),
              10000.0//tube(rep2(pos.yz, 8.0), .5)
              );
}

vec3 normal(vec3 pos) {
  return normalize(vec3(
                        dist(pos) - dist(vec3(pos.x - EPS, pos.y, pos.z)),
                        dist(pos) - dist(vec3(pos.x, pos.y - EPS, pos.z)),
                        dist(pos) - dist(vec3(pos.x, pos.y, pos.z - EPS))
                        ));
}

vec3 bg(vec2 pos) {
  return vec3(pos / 2.0 + 0.5, 1.0);
}

void fragment() {
  vec2 resolution = (1.0 / SCREEN_PIXEL_SIZE);
  vec2 pos = (FRAGCOORD.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y) * 0.75;
  vec2 mousepos = mouse * 7.0 - 1.0;
  pos = rot2d(pos, TIME / 10.0);
  mousepos = rot2d(mousepos, TIME / 10.0);

  vec3 campos = vec3(2. * mousepos.x, -2. * mousepos.y, 5.0 + TIME);
  vec3 camdir = vec3(0, 0, 1);
  vec3 right = normalize(cross(camdir, vec3(0, 1, 0)));
  vec3 up = normalize(cross(right, camdir));
  vec3 raydir = normalize(pos.x * right + pos.y * up + camdir * 1.0);
  vec3 lightdir = - camdir;

  vec3 color = bg(pos);

  vec3 march = campos;
  for (int i = 0; i < 40; i++) {
    float dist = dist(march);

    if (dist < EPS) {
      vec3 normal = normal(march);
      float light = clamp(dot(normal, lightdir), 0.1, 1.0);
      float depth = pow(clamp(distance(campos, march) / 65.0, 0.0, 1.0), 2.0);
      color = mix(color, vec3(light) + vec3(.2, .2, .2), 1.0 - (1.8-depth));
      break;
    }

    march += raydir * dist;
  }

  COLOR = vec4(color, 1.0);
}
