precision highp float;
uniform vec2 resolution;
uniform float time;

float e(vec3 c, float r)
{
  c = cos(vec3(cos(c.r+r/6.)*c.r-cos(c.g+r/5.)*c.g,c.b/3.*c.r-cos(r/7.)*c.g,c.r+c.g+c. b+r));
  return dot(c*c,vec3(1.))-1.0;
}

void main()
{
  vec2 c=-1.+2.0*gl_FragCoord.rg/resolution.xy;
  vec3 o=vec3(0.),g=vec3(c.x,c.y,1.0)/44.;
  vec4 v=vec4(0.);
  float t=time/3.,i,ii;
  for(float i=0.;i<600.;i+=1.0)
    {
      vec3 vct = o+g*i;
      float scn = e(vct, t);
      if(scn<.4)
        {
          break;
        }
        ii=i;
    }
  gl_FragColor=vec4(.1+cos(t/14.)/9.,0.1,.1-cos(t/3.)/19.,1.)*(ii/66.);
}