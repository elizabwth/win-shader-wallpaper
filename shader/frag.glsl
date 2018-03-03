#version 330 core

in vec4 v_color;
out vec4 color_frag;
//uniform float time = 0;
//uniform vec3 color = vec3(1.0, 1.0, 1.0);

void main()
{
  color_frag = v_color;
}
