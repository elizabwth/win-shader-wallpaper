/*
 * Original shader from: https://www.shadertoy.com/view/XlG3zW
 */

#ifdef GL_ES
precision mediump float;
#endif

// glslsandbox uniforms
uniform float time;
uniform vec2 resolution;

// shadertoy globals
float iTime;
vec3  iResolution;

// --------[ Original ShaderToy begins here ]---------- ////Beestie by eiffie based on marius's strandbeest leg https://www.shadertoy.com/view/ltG3z1
//which is based on...
// Visualizing Theo Jansen's Strandbeest basic leg linkage
// http://www.strandbeest.com/
//
// See http://www.strandbeest.com/beests_leg.php for names & values.

const float SCALE = 100.0;

const float a = 38.0 / SCALE;
const float b = 41.5 / SCALE;
const float c = 39.3 / SCALE;
const float d = 40.1 / SCALE;
const float e = 55.8 / SCALE;
const float f = 39.4 / SCALE;
const float g = 36.7 / SCALE;
const float h = 65.7 / SCALE;
const float i = 49.0 / SCALE;
const float j = 50.0 / SCALE;
const float k = 61.9 / SCALE;
const float l = 7.8  / SCALE;
const float m = 15.0 / SCALE;

// distance from point p to line segment ab
vec2 seg(vec2 a, vec2 b, vec2 p){
  vec2 pa=p-a,ba=b-a;
  float t=dot(pa,ba)/dot(ba,ba);
  float d=length(pa-ba*clamp(t,0.0,1.0));
  return vec2(d,max(d,0.5-abs(t-0.5)));
}
// intersect point between two 2d circles (x,y,r)
vec2 intersect(vec3 c0, vec3 c1) {
    vec2 dxy = vec2(c1.xy - c0.xy);
    float d = length(dxy);
    float a = (c0.z*c0.z - c1.z*c1.z + d*d)/(2.*d);
    vec2 p2 = c0.xy + (a / d)*dxy;
    float h = sqrt(c0.z*c0.z - a*a);
    vec2 rxy = vec2(-dxy.y, dxy.x) * (h/d);
    return p2 + rxy;
}
float iZ;
vec3 mcol=vec3(0.0);
float DE(vec3 p0){//drawing multiple legs by marching one
  float sx=1.0,dB=max(abs(p0.x)-2.0,abs(p0.z)-3.75);
  p0.y+=sin(p0.z*0.4+2.4*sin(p0.x*0.3+time*0.1))*0.25;
  if(p0.x<0.0){sx=-1.0;p0.z-=0.5;}
  float t=(time*2.0+(sin(time*0.1)+2.0)*floor(p0.z)+1.57*sx)*sx;
  float x=sx*p0.x-0.2;
  //leg from marius
  vec2 crank = vec2(0, 0);          // crank axle
  vec2 axle = crank - vec2(a, -l);  // main axle
  vec2 pedal = crank + vec2(m*cos(t), -m*sin(t));
  vec2 uv=vec2(-x,-p0.y);
  // draw "frame"
  vec2 ds = seg(vec2(0, l), axle, uv);
  ds = min(ds, seg(vec2(0, l), crank, uv));
  ds = min(ds, seg(pedal, crank, uv));
  // compute linkage points
  vec2 P1 = intersect(vec3(pedal, j), vec3(axle, b));  // bej
  vec2 P2 = intersect(vec3(axle, c), vec3(pedal, k));  // cgik
  vec2 P3 = intersect(vec3(P1, e), vec3(axle, d));  // edf
  vec2 P4 = intersect(vec3(P3, f), vec3(P2, g)); // fgh
  vec2 P5 = intersect(vec3(P4, h), vec3(P2, i));  // hi
  ds = min(ds, seg(P1, axle, uv));
  ds = min(ds, seg(P3, axle, uv));
  ds = min(ds, seg(P1, P3, uv));
  ds = min(ds, seg(P2, P4, uv));
  ds = min(ds, seg(P2, P5, uv));
  ds = min(ds, seg(P4, P5, uv));
  ds = min(ds, seg(pedal, P1, uv));
  ds = min(ds, seg(pedal, P2, uv));
  ds = min(ds, seg(P2, axle, uv));
  ds = min(ds, seg(P3, P4, uv));
  //end leg
  float z=abs(fract(p0.z)-0.5)-0.2;
  float d2=max(ds.y,z);
  float d3=min(length(uv),length(uv-axle));
  float d=sqrt(ds.x*ds.x+z*z);
  d=min(min(min(d,min(d2,d3))-0.01,(1.2-fract(p0.z))*iZ),abs(p0.x)+0.2);
  d=max(d,abs(p0.z)-3.75);
  d2=0.95+p0.y;
  if(d<d2)mcol=vec3(0.7,0.4,0.2);
  else mcol=vec3(0.9,0.7,0.4)*(0.5+0.5*fract(sin(dot(p0.xz,vec2(13.13,117.667)))*43.1234));
  return min(d,d2);
}
vec3 sky(vec3 rd, vec3 L){//modified bananaft's & public_int_i's code
  float d=0.4*dot(rd,L)+0.6;
  rd=abs(rd);
  float y=max(0.,L.y),sun=max(1.-(1.+10.*y+rd.y)*length(rd-L),0.)
    +.3*pow(1.-rd.y,12.)*(1.6-y);
  return d*mix(vec3(0.3984,0.5117,0.7305),vec3(0.7031,0.4687,0.1055),sun)
    *((.5+pow(y,.4))*(1.5-abs(L.y))+pow(sun,5.2)*y*(5.+15.0*y));
}
float rnd;
void randomize(in vec2 p){rnd=fract(time+sin(dot(p,vec2(13.3145,117.7391)))*42317.7654321);}
float ShadAO(in vec3 ro, in vec3 rd){
 float t=0.01*rnd,s=1.0,d,mn=0.01;
 for(int i=0;i<12;i++){
  d=max(DE(ro+rd*t)*1.5,mn);
  s=min(s,d/t+t*0.5);
  t+=d;
 }
 return s;
}
vec3 scene(vec3 ro, vec3 rd){
  iZ=1.0/rd.z;
  vec3 L=normalize(vec3(0.4,0.7,0.5));
  vec3 bcol=sky(rd,L);
  vec4 col=vec4(0.0);//color accumulator
  float t=DE(ro)*rnd,d,od=1.0,px=1.0/iResolution.x;
  for(int i=0;i<99;i++){
    d=DE(ro+rd*t);
    if(d<px*t){
      float dif=clamp(1.0-d/od,0.0,1.0);
      float alpha=(1.0-col.w)*clamp(1.0-d/(px*t),0.0,1.0);
      if(mcol.g>0.5)dif=0.1+dif*0.5;
      col+=vec4(clamp(mcol*dif,0.0,1.0),1.0)*alpha;
      if(col.w>0.99)break;
    }
    t+=d;od=d;
    if(t>30.0)break;
  }
  ro+=rd*t;
  if(t<30.0){
    col.rgb*=(0.5+0.5*ShadAO(ro,L));
    if(ro.y<0.0)col.w=1.0;
  }
  col.rgb+=bcol*(1.0-clamp(col.w,0.0,1.0));
  return col.rgb;
}

mat3 lookat(vec3 fw){
 fw=normalize(fw);vec3 rt=normalize(cross(fw,vec3(0.0,1.0,0.0)));return mat3(rt,cross(rt,fw),fw);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
   randomize(fragCoord);
   float tim=iTime*0.3;
   vec2 uv=(fragCoord-0.5*iResolution.xy)/iResolution.x;
   vec3 ro=vec3(sin(tim)+3.5,sin(tim*0.4)*0.75+0.25,-5.0+cos(tim*1.3)*2.0)*(sin(tim*0.2)*0.5+1.0);
   vec3 rd=lookat(vec3(0.0,-0.5,0.0)-ro)*normalize(vec3(uv,1.0));
   fragColor=vec4(scene(ro,rd)*2.0,1.0);
}

// --------[ Original ShaderToy ends here ]---------- //

void main(void)
{
    iTime = time;
    iResolution = vec3(resolution, 0.0);

    mainImage(gl_FragColor, gl_FragCoord.xy);
}
