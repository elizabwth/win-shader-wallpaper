#version 330 core
uniform float time = 0;
uniform vec2 mouse = vec2(0, 0);
uniform vec2 resolution = vec2(100, 100);

uniform float vertexCount;
uniform sampler2D volume;
uniform sampler2D sound;
uniform sampler2D floatSound;
uniform sampler2D touch;
uniform vec2 soundRes;

layout(location = 0)in vec3 vert;
out vec4 v_color;

//////
// Created by Stephane Cuillerdier - Aiekick/2017 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// mouse axis x => contorl section compelxity
// mouse axis y => controe torus complexity

mat4 persp(float fov, float aspect, float zNear, float zFar);
mat4 cameraLookAt(vec3 eye, vec3 target, vec3 up);

void main()
{
  gl_PointSize = 3.;
  
  float pi = radians(180.);
  float pi2 = radians(360.);
  
  vec2 mo = 0.5 - mouse;
  
  // vars
  // count point : 6 * quadsPerPolygon * countPolygon => here 3600
  float quadsPerPolygon = clamp(floor(10. * (mo.x*0.5+0.5)), 3., 10.);
  float countPolygon = clamp(floor(200. * (mo.y*0.5+0.5)), 3., 200.);
  float radius = 20.;
  float thickNess = 5.;
  float zoom = 2.;
  
  float countMax = 6. * quadsPerPolygon * countPolygon;
  
  float index = mod(gl_VertexID, 6.);
  
  float indexQuad = floor(gl_VertexID / 6.);
  float asp = pi * 2.0 / quadsPerPolygon; // angle step polygon
  float ap0 = asp * indexQuad; // angle polygon 0
  float ap1 = asp * (indexQuad + 1.); // angle polygon 0
  
  float indexPolygon = floor(indexQuad / quadsPerPolygon);
  float ast = pi * 2.0 / countPolygon; // angle step torus
  float at0 = ast * indexPolygon; // angle torus 0
  float at1 = ast * (indexPolygon + 1.); // angle torus 1
  
  vec2 st = vec2(0);
  
  // triangle 1
  if (index == 0.) st = vec2(ap0, at0);
  if (index == 1.) st = vec2(ap1, at0);
  if (index == 2.) st = vec2(ap1, at1);
  
  // triangle 2
  if (index == 3.) st = vec2(ap0, at0);
  if (index == 4.) st = vec2(ap1, at1);
  if (index == 5.) st = vec2(ap0, at1);
  
  vec3 p = vec3(cos(st.x),st.y,sin(st.x));
  
  // twist
  float ap = st.y - cos(st.y) + time;
      
  // polygon
  p.xz *= thickNess;
  p.xz *= mat2(cos(ap), sin(ap), -sin(ap), cos(ap));
  
  // torus
  p.x += radius;
  float at = p.y; p.y = 0.0;
  p.xy *= mat2(cos(at), sin(at), -sin(at), cos(at));
  
  // camera
  float ca = 0.5;//time * 0.1;
  float cd = 100.;
  vec3 eye = vec3(sin(ca), 0., cos(ca)) * cd;
  vec3 target = vec3(0, 0, 0);
  vec3 up = vec3(0, 1, 0);
  mat4 camera = persp(45. * pi / 180., resolution.x / resolution.y, 0.1, 10000.) * 
    cameraLookAt(eye, target, up);
  
  // vertex position
  if (gl_VertexID < countMax)
  {
    gl_Position = camera * vec4(p,1);
  }
  else
  {
    gl_Position = vec4(0,0,0,0);
  }
  
  // face color
  indexQuad = mod(indexQuad, quadsPerPolygon);
  v_color = cos(vec4(10,20,30,1) + indexQuad);
  v_color = mix(v_color, vec4(normalize(p) * 0.5 + 0.5, 1), .5);
  v_color.a = 1.0;
}

//////////////////////////////////////////////////////////////////////////

#define PI radians(180.)

mat4 persp(float fov, float aspect, float zNear, float zFar) {
  float f = tan(PI * 0.5 - 0.5 * fov);
  float rangeInv = 1.0 / (zNear - zFar);

  return mat4(
  f / aspect, 0, 0, 0,
  0, f, 0, 0,
  0, 0, (zNear + zFar) * rangeInv, -1,
  0, 0, zNear * zFar * rangeInv * 2., 0);
}


mat4 lookAt(vec3 eye, vec3 target, vec3 up) {
  vec3 zAxis = normalize(eye - target);
  vec3 xAxis = normalize(cross(up, zAxis));
  vec3 yAxis = cross(zAxis, xAxis);

  return mat4(
  xAxis, 0,
  yAxis, 0,
  zAxis, 0,
  eye, 1);
}

mat4 inverse(mat4 m) {
  float
    a00 = m[0][0], a01 = m[0][1], a02 = m[0][2], a03 = m[0][3],
    a10 = m[1][0], a11 = m[1][1], a12 = m[1][2], a13 = m[1][3],
    a20 = m[2][0], a21 = m[2][1], a22 = m[2][2], a23 = m[2][3],
    a30 = m[3][0], a31 = m[3][1], a32 = m[3][2], a33 = m[3][3],

    b00 = a00 * a11 - a01 * a10,
    b01 = a00 * a12 - a02 * a10,
    b02 = a00 * a13 - a03 * a10,
    b03 = a01 * a12 - a02 * a11,
    b04 = a01 * a13 - a03 * a11,
    b05 = a02 * a13 - a03 * a12,
    b06 = a20 * a31 - a21 * a30,
    b07 = a20 * a32 - a22 * a30,
    b08 = a20 * a33 - a23 * a30,
    b09 = a21 * a32 - a22 * a31,
    b10 = a21 * a33 - a23 * a31,
    b11 = a22 * a33 - a23 * a32,

    det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

  return mat4(
    a11 * b11 - a12 * b10 + a13 * b09,
    a02 * b10 - a01 * b11 - a03 * b09,
    a31 * b05 - a32 * b04 + a33 * b03,
    a22 * b04 - a21 * b05 - a23 * b03,
    a12 * b08 - a10 * b11 - a13 * b07,
    a00 * b11 - a02 * b08 + a03 * b07,
    a32 * b02 - a30 * b05 - a33 * b01,
    a20 * b05 - a22 * b02 + a23 * b01,
    a10 * b10 - a11 * b08 + a13 * b06,
    a01 * b08 - a00 * b10 - a03 * b06,
    a30 * b04 - a31 * b02 + a33 * b00,
    a21 * b02 - a20 * b04 - a23 * b00,
    a11 * b07 - a10 * b09 - a12 * b06,
    a00 * b09 - a01 * b07 + a02 * b06,
    a31 * b01 - a30 * b03 - a32 * b00,
    a20 * b03 - a21 * b01 + a22 * b00) / det;
}

mat4 cameraLookAt(vec3 eye, vec3 target, vec3 up) {
  #if 1
  return inverse(lookAt(eye, target, up));
  #else
  vec3 zAxis = normalize(target - eye);
  vec3 xAxis = normalize(cross(up, zAxis));
  vec3 yAxis = cross(zAxis, xAxis);

  return mat4(
  xAxis, 0,
  yAxis, 0,
  zAxis, 0,
  -dot(xAxis, eye), -dot(yAxis, eye), -dot(zAxis, eye), 1);  
  #endif
}