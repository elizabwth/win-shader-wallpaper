
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

void main(){
	gl_Position=vec4(gl_VertexID/vertexCount*2.-1.,sin(mod(gl_VertexID,8.)*gl_VertexID+time),0,1);
	v_color=vec4(0,1,0,1);
}
