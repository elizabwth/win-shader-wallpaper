// This is a snapshot of the GLSL ray marching renderer
// Michele Bianchi and I (Nicolas Silva) are working on,
// adapted to webgl (it's a school project).
//
// Just copy paste it on iq's ShaderToy (http://www.iquilezles.org/apps/shadertoy/) to see it working.
//
// the project is here : http://github.com/nical/GLSL-Raymarching
// It's open source, feel free to use it :)
// Please tell me on twitter (@nicalsilva) if you like it or if it's been useful
// to you!
// Pretty much all we've learned about ray marching comes from
// iq's website: http://www.iquilezles.org/
//
// Enjoy!


#ifdef GL_ES
precision highp float;
#endif

uniform float time;
#define time time * 30.0
uniform vec2 resolution;
uniform vec4 mouse;
uniform sampler2D tex0;
uniform sampler2D tex1;


#define MAX_STEPS 200

#define shadowColor vec3(0.0,0.3,0.7)
#define buildingsColor vec3(1.0,1.0,1.0)
#define groundColor vec3(1.0,1.0,1.0)
#define redColor vec3(1.0,0.1,0.1)
#define skyColor vec3(0.9,1.0,1.0)
#define viewMatrix mat4(0.0)
#define fovyCoefficient 1.0
#define shadowHardness 7.0



#define epsilon 0.01
#define PI 3.14159265

#define NO_HIT 0
#define HAS_HIT 1
// materials
#define SKY_MTL 0
#define GROUND_MTL 1
#define BUILDINGS_MTL 2
#define RED_MTL 3


float PlaneDistance(in vec3 point, in vec3 normal, in float pDistance)
{
return dot(point - (normal * pDistance), normal);
}

float SphereDistance(vec3 point, vec3 center, float radius)
{
  point.z = mod(point.z+15.0, 230.0)-15.0;
  point.x = mod(point.x+15.0, 230.0)-15.0;
  //point.y = mod(point.y, 30.0);
  return length(point - center) - radius;
}


float CubeDistance2 (in vec3 point, in vec3 size) {

  return length(max(abs(point)-size, 0.0));
}

vec3 DistanceRepetition(in vec3 point, in vec3 repetition ) {
  vec3 q = mod(point, repetition)-0.5*repetition;
  return q;
}


float CubeRepetition(in vec3 point, in vec3 repetition ) {
    vec3 q = mod(point, repetition)-0.5*repetition;
    q.y = point.y;
    return CubeDistance2 ( q, vec3 (2.0, 6.0, 2.0));
}

void applyFog( in float distance, inout vec3 rgb ){

    float fogAmount = (1.0 - clamp(distance*0.0015,0.0,1.0) );
    //float fogAmount = exp( -distance* 0.006 );
    vec3 fogColor = vec3(0.9,0.95,1);
    //if( fogAmount < 0.6 )
    //  rgb = vec3(1.0,1.0,0.0);
    //else
    //rgb = clamp( rgb, 0.0, 1.0);
    rgb = mix( skyColor, rgb, fogAmount );
}


float RedDistance(in vec3 position)
{
    return SphereDistance(position, vec3(0.0, 3.0, 5.0), 10.0);
}

float BuildingsDistance(in vec3 position)
{
    return min(
      CubeRepetition(position, vec3(5.0, 0.0, 20.0))
      , CubeRepetition(position+vec3(350.0,-2.0,0.0), vec3(23.0, 0.0, 23.0))
    );
}

float GroundDistance(in vec3 position)
{
    return PlaneDistance(position, vec3(0.0,1.0,0.0), 0.0);
}

float DistanceField(in vec3 position, out int mtl )
{
    float redDistance = RedDistance(position);
    float bldDistance = BuildingsDistance(position);
    float gndDistance = GroundDistance(position);
    float closest = gndDistance;
    mtl = GROUND_MTL;
    if ( bldDistance < closest )
    {
        closest = bldDistance;
        mtl = BUILDINGS_MTL;
    }
    if ( redDistance < closest )
    {
        closest = redDistance;
        mtl = RED_MTL;
    }
    return closest;
}


float Softshadow( in vec3 landPoint, in vec3 lightVector, float mint, float maxt, float iterations )
{
    float penumbraFactor = 1.0;
    vec3 sphereNormal;
    float t = mint; //(mint + rand(gl_FragCoord.xy) * 0.01);
    for( int s = 0; s < 100; ++s )
    {
        if(t > maxt) break;
        float nextDist = min(
            BuildingsDistance(landPoint + lightVector * t )
            , RedDistance(landPoint + lightVector * t )
        );

        if( nextDist < 0.001 ){
            return 0.0;
        }
        //float penuAttenuation = mix (1.0, 0.0, t/maxt);
        penumbraFactor = min( penumbraFactor, iterations * nextDist / t );
        t += nextDist;
    }
    return penumbraFactor;
}


vec3 RayMarch(in vec3 position, in vec3 direction, out int mtl)
{
    float nextDistance = 1.0;
    for (int i = 0; i < MAX_STEPS ; ++i)
    {
        nextDistance = DistanceField(position,mtl);

        if ( nextDistance < 0.01)
        {
            return position;
        }
        position += direction * nextDistance;
    }
    // out of steps
    if (direction.y < 0.0 )
    {
        mtl = GROUND_MTL;
    }
    else
    {
        mtl = SKY_MTL;
    }
    return position;
}

vec3 MaterialColor( int mtl )
{
    if(mtl==SKY_MTL) return skyColor;
    if(mtl==BUILDINGS_MTL) return buildingsColor;
    if(mtl==GROUND_MTL) return groundColor;
    if(mtl==RED_MTL) return redColor;

    return vec3(1.0,0.0,1.0); // means error
}

vec3 ComputeNormal(vec3 pos, int material)
{
    int dummy;
    return normalize(
        vec3(
          DistanceField( vec3(pos.x + epsilon, pos.y, pos.z), dummy ) - DistanceField( vec3(pos.x - epsilon, pos.y, pos.z), dummy )
        , DistanceField( vec3(pos.x, pos.y + epsilon, pos.z), dummy ) - DistanceField( vec3(pos.x, pos.y - epsilon, pos.z), dummy )
        , DistanceField( vec3(pos.x, pos.y, pos.z + epsilon), dummy ) - DistanceField( vec3(pos.x, pos.y, pos.z - epsilon), dummy )
        )
    );
}

void FishEyeCamera( vec2 screenPos, float ratio, float fovy, mat4 transform, out vec3 position, out vec3 direction )
{
    screenPos.y -= 0.2;
    screenPos *= vec2(PI*0.5,PI*0.5/ratio)/fovy;

    direction = vec3(
           sin(screenPos.y+PI*0.5)*sin(screenPos.x)
        , -cos(screenPos.y+PI*0.5)
        , sin(screenPos.y+PI*0.5)*cos(screenPos.x)
    );
    position = vec3(5.0*sin(time*0.01), 15.0, time);
}


float AmbientOcclusion (vec3 point, vec3 normal, float stepDistance, float samples)
{
  float occlusion = 1.0;
  int tempMaterial;

  for (int i = 0; i < 20; ++i )
  {
    if(--samples < 0.0) break;
    occlusion -= (samples * stepDistance - (DistanceField( point + normal * samples * stepDistance, tempMaterial))) / pow(2.0, samples);
  }
  return occlusion;
}

void main(void)
{
    float ratio = resolution.x / resolution.y;
    // position on the screen
    vec2 screenPos;
    screenPos.x = (gl_FragCoord.x/resolution.x - 0.5);
    screenPos.y = gl_FragCoord.y/resolution.y - 0.5;

    vec3 direction;
    vec3 position;
    FishEyeCamera(screenPos, ratio, fovyCoefficient, viewMatrix, position, direction);
    int material;
    vec3 hitPosition = RayMarch(position, direction, material);

    if( material == SKY_MTL && direction.y < 0.0 )
    {
       material = GROUND_MTL;
       gl_FragColor = vec4(1.0,0.0,0.0,1.0);
    }


    vec3 hitColor;
    if( material != SKY_MTL ) // has hit something
    {
        vec3 lightpos = vec3(50.0 * sin(time*0.01), 10.0 + 40.0 * abs(cos(time*0.01)), (time) + 100.0 );
        vec3 lightVector = normalize(lightpos - hitPosition);
        // soft shadows
        float shadow = Softshadow(hitPosition, lightVector, 0.1, 50.0, shadowHardness);
        // attenuation due to facing (or not) the light
        vec3 normal = ComputeNormal(hitPosition, material);
        float attenuation = clamp(dot(normal, lightVector),0.0,1.0)*0.6 + 0.4;
        shadow = min(shadow, attenuation);
        //material color
        vec3 mtlColor = MaterialColor(material);

        if(material == BUILDINGS_MTL){
          mtlColor = mix(shadowColor, mtlColor, clamp(hitPosition.y/7.0, 0.0, 1.0));
        }
        hitColor = mix(shadowColor, mtlColor, 0.4+shadow*0.6);
        vec3 hitNormal = ComputeNormal(hitPosition, 0);
        float AO = AmbientOcclusion(hitPosition, hitNormal, 0.35, 5.0);
        hitColor = mix(shadowColor, hitColor, AO);

        applyFog( length(position-hitPosition), hitColor);
        gl_FragColor = vec4(hitColor, 1.0);
    }
    else // sky
    {
        float shade = direction.y;
        vec3 hitColor = mix(skyColor, vec3(0.3,0.3,0.7), shade);
        gl_FragColor = vec4(hitColor, 1.0);
    }

}