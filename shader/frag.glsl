#version 330 core

uniform float time;
uniform vec3 color = vec3(1.0, 1.0, 1.0);
out vec4 color_frag;


void main()
{
  color_frag = vec4(color, 1.0);
}
