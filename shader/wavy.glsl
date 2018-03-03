// https://www.vertexshaderart.com/art/ZWM6nHwzqNcfrMCbQ

#version 330 core
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

uniform float vertexCount;
uniform sampler2D volume;
uniform sampler2D sound;
uniform sampler2D floatSound;
uniform sampler2D touch;
uniform vec2 soundRes;

layout(location = 0)in vec3 vert;
out vec4 v_color;

void main()
{
  float width = floor(sqrt(vertexCount));
  
  float x = mod(gl_VertexID, width);
  float y = floor(gl_VertexID / width);
  
  float u = x / (width - 1.0);
  float v = y / (width - 1.0);
  
  float xOffset = cos(time + y * 0.2) * 0.1;
  float yOffset = cos(time + x * 0.3) * 0.2;
  
  float ux = u * 2.0 - 1.0 + xOffset;
  float vy = v * 2.0 - 1.0 + yOffset;
  
  // gl_VertexID 0 1 2 ... 10 11 12 13 ... 20 21 22
  //mod       0 1 2 ...  0  1  2  3 ...  0  1  2  (residuo)    X
  //floor     0 0 0 ...  1  1  1  1 ...  2  2  2  (divididos)  Y
  
  vec2 xy = vec2(ux, vy) * 1.2;
   
  gl_Position = vec4 (xy, 0.0, 1.0);
  
  float sizeOffset = sin(time + x * y * 0.2) * 5.0;
  gl_PointSize = 10.0 + sizeOffset;
  gl_PointSize *= 32.0 / width;
  
  v_color= vec4(0.0, 1.0, 0.0, 1.0);
}