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


// Garden Fireworks - @P_Malin
// Playing with motion blurred hexagonal bokeh

#define SHAKY_CAM

float Cross( const in vec2 A, const in vec2 B )
{
    return A.x * B.y - A.y * B.x;
}

void GetTriInfo( const float vertexIndex, out vec2 triVertId, out float triId )
{
    float triVertexIndex = mod( vertexIndex, 3.0 );
  
    if 		( triVertexIndex < 0.5 ) 	triVertId = vec2( 0.0, 0.0 );
    else if	( triVertexIndex < 1.5 )	triVertId = vec2( 1.0, 1.0 );
    else 								triVertId = vec2( 0.0, 1.0 );

    triId = floor( vertexIndex / 3.0 );
}

void GetQuadInfo( const float vertexIndex, out vec2 quadVertId, out float quadId )
{
    float twoTriVertexIndex = mod( vertexIndex, 6.0 );
    float triVertexIndex = mod( vertexIndex, 3.0 );
  
    if 		( twoTriVertexIndex < 0.5 ) quadVertId = vec2( 0.0, 0.0 );
    else if	( twoTriVertexIndex < 1.5 )	quadVertId = vec2( 1.0, 0.0 );
    else if ( twoTriVertexIndex < 2.5 )	quadVertId = vec2( 0.0, 1.0 );
    else if ( twoTriVertexIndex < 3.5 )	quadVertId = vec2( 1.0, 0.0 );
    else if ( twoTriVertexIndex < 4.5 )	quadVertId = vec2( 1.0, 1.0 );
    else 								quadVertId = vec2( 0.0, 1.0 );

    quadId = floor( vertexIndex / 6.0 );
}

void GetMatrixFromZY( const vec3 vZ, const vec3 vY, out mat3 m )
{
   vec3 vX = normalize( cross( vY, vZ ) );
   vec3 vOrthoY = normalize( cross( vZ, vX ) );
   m[0] = vX;
   m[1] = vOrthoY;
   m[2] = vZ;
}


void GetMatrixFromZ( vec3 vZAxis, out mat3 m )
{
  	vec3 vZ = normalize(vZAxis);
   	vec3 vY = vec3( 0.0, 1.0, 0.0 );
  	if ( abs(vZ.y) > 0.99 )
    {
       vY = vec3( 1.0, 0.0, 0.0 );
    }
  	GetMatrixFromZY( vZ, vY, m );
}


mat3 RotMatrixX( float fAngle )
{
    float s = sin( fAngle );
    float c = cos( fAngle );
  	
    return mat3( 1.0, 0.0, 0.0, 
                 0.0, c, s,
                 0.0, -s, c );  
}


mat3 RotMatrixY( float fAngle )
{
    float s = sin( fAngle );
    float c = cos( fAngle );
  	
    return mat3( c, 0.0, s, 
                         0.0, 1.0, 0.0,
                         -s, 0.0, c );
  
}


mat3 RotMatrixZ( float fAngle )
{
    float s = sin( fAngle );
    float c = cos( fAngle );
  	
    return mat3( c, s, 0.0, 
                 -s, c, 0.0,
                 0.0, 0.0, 1.0 );
  
}

// hash function from https://www.shadertoy.com/view/4djSRW
float Hash(float p)
{
	vec2 p2 = fract(vec2(p * 5.3983, p * 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}

#define MOD3 vec3(.1031,.11369,.13787)
#define MOD4 vec4(.1031,.11369,.13787, .09987)
vec3 Hash3(float p)
{
   vec3 p3 = fract(vec3(p) * MOD3);
   p3 += dot(p3, p3.yzx + 19.19);
   return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

vec3 Hash32(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}


vec3 Noise23( vec2 p )
{
	vec2 fl = floor(p);

	vec3 h00 = Hash32( fl + vec2( 0.0, 0.0 ) );
	vec3 h10 = Hash32( fl + vec2( 1.0, 0.0 ) );
	vec3 h01 = Hash32( fl + vec2( 0.0, 1.0 ) );
	vec3 h11 = Hash32( fl + vec2( 1.0, 1.0 ) );

	vec2 fr = p - fl;
	
	vec2 fr2 = fr * fr;
	vec2 fr3 = fr2 * fr;
	
	vec2 t1 = 3.0 * fr2 - 2.0 * fr3;	
	vec2 t0 = 1.0 - t1;
	
	return h00 * t0.x * t0.y
		 + h10 * t1.x * t0.y
		 + h01 * t0.x * t1.y
		 + h11 * t1.x * t1.y;
}

struct CameraSettings
{
  float fAperture;
  float fFocalLength;
  float fPlaneInFocus; 
  float fExposure;
};

struct CameraPosition
{
  	vec3 vPosition;
  	vec3 vTarget;
  	vec3 vUp;
  
  	mat3 mRotation;
};
  
struct OutVertex
{
  	vec2 vPos;
  	vec3 vColor;
};  
  
#define HEXAGON_OUTLINE_VERTEX_COUNT 	6.0 * (6.0 + 2.0)

void GetHexagonOutlineVertex( CameraSettings settings, const float fVertexIndex, const vec2 vOrigin, const vec2 vDir, const float r0, const float r1, const vec3 col0, const vec3 col1, inout OutVertex vertex )
{
  	float fAngleOffset = settings.fAperture * 0.5;
  
  	if ( fVertexIndex < 6.0 * 6.0 ) 
    {
      float fQuadId;

      vec2 vQuadVertId;
      GetQuadInfo( fVertexIndex, vQuadVertId, fQuadId );

      float fIndex = fQuadId + vQuadVertId.x;

      float fAngle = fIndex * radians(360.0) / 6.0;

      float fRadius = mix( r0, r1, vQuadVertId.y);

      vec2 vPos = vec2( sin( fAngle + fAngleOffset), cos( fAngle + fAngleOffset) ) * fRadius;

      float fCurrIndex = fQuadId;
      float fCurrAngle = fCurrIndex * radians(360.0) / 6.0;
      vec2 vCurrPos = vec2( sin( fCurrAngle + fAngleOffset), cos( fCurrAngle + fAngleOffset) );

      float fNextIndex = fQuadId + 1.0;
      float fNextAngle = fNextIndex * radians(360.0) / 6.0;
      vec2 vNextPos = vec2( sin( fNextAngle + fAngleOffset), cos( fNextAngle + fAngleOffset) );

      if ( Cross( vNextPos - vCurrPos, vDir ) >= 0.0 )
      {
          vPos += vDir;
      }

      vertex.vPos.xy = vOrigin + vPos;
      vertex.vColor.rgb = mix( col0, col1, vQuadVertId.y );
    }
    else
    {
	  float fVertexIndexB = fVertexIndex - 6.0 * 6.0;
      float fQuadId;

      vec2 vQuadVertId;
      GetQuadInfo( fVertexIndexB, vQuadVertId, fQuadId );
      
      float fEdgeAngle = atan( vDir.x, vDir.y )- fAngleOffset;
      
      fEdgeAngle = floor( fEdgeAngle * 6.0 / radians(360.0) - 1.0 ) * radians(360.0) / 6.0;
      
      if ( fQuadId > 0.0 )
      {
		fEdgeAngle += radians( 180.0 );
      }
      
      float fRadius = mix( r0, r1, vQuadVertId.y);
      vec2 vPos = vec2( sin( fEdgeAngle + fAngleOffset), cos( fEdgeAngle + fAngleOffset) ) * fRadius;
      vPos += vDir * vQuadVertId.x;

      vertex.vPos.xy = vOrigin + vPos;
      vertex.vColor.rgb = mix( col0, col1, vQuadVertId.y );
    }
}
  
#define HEXAGON_VERTEX_COUNT (6.0 * 3.0 + 6.0 * 2.0)
void GetHexagonVertex( CameraSettings settings, const float fVertexIndex, const vec2 vOrigin, const vec2 vDir, const float r, const vec3 col0, const vec3 col1, inout OutVertex vertex )
{
  	float fAngleOffset = settings.fAperture * 0.5;
  
  	if ( fVertexIndex < 6.0 * 3.0 ) 
    {
      float fTriId;

      vec2 vTriVertId;
      GetTriInfo( fVertexIndex, vTriVertId, fTriId );

      float fIndex = fTriId + vTriVertId.x;

      float fAngle = fIndex * radians(360.0) / 6.0;

      float fRadius = vTriVertId.y * r;

      vec2 vPos = vec2( sin( fAngle + fAngleOffset), cos( fAngle + fAngleOffset) ) * fRadius;

      float fCurrIndex = fTriId;
      float fCurrAngle = fCurrIndex * radians(360.0) / 6.0;
      vec2 vCurrPos = vec2( sin( fCurrAngle + fAngleOffset), cos( fCurrAngle + fAngleOffset) );

      float fNextIndex = fTriId + 1.0;
      float fNextAngle = fNextIndex * radians(360.0) / 6.0;
      vec2 vNextPos = vec2( sin( fNextAngle + fAngleOffset), cos( fNextAngle + fAngleOffset) );

      if ( Cross( vNextPos - vCurrPos, vDir ) >= 0.0 )
      {
          vPos += vDir;
      }

      vertex.vPos.xy = vOrigin + vPos;
      vertex.vColor.rgb = mix( col0, col1, vTriVertId.y );
    }
    else
    {
	  float fVertexIndexB = fVertexIndex - 6.0 * 3.0;
      float fQuadId;

      vec2 vQuadVertId;
      GetQuadInfo( fVertexIndexB, vQuadVertId, fQuadId );
      
      float fEdgeAngle = atan( vDir.x, vDir.y )- fAngleOffset;
      
      fEdgeAngle = floor( fEdgeAngle * 6.0 / radians(360.0) - 1.0 ) * radians(360.0) / 6.0;
      
      if ( fQuadId > 0.0 )
      {
		fEdgeAngle += radians( 180.0 );
      }
      
      float fRadius = vQuadVertId.y * r;
      vec2 vPos = vec2( sin( fEdgeAngle + fAngleOffset), cos( fEdgeAngle + fAngleOffset) ) * fRadius;
      vPos += vDir * vQuadVertId.x;

      vertex.vPos.xy = vOrigin + vPos;
      vertex.vColor.rgb = mix( col0, col1, vQuadVertId.y );
    }
}


#define BOKEH_VERTEX_COUNT ( HEXAGON_VERTEX_COUNT + HEXAGON_OUTLINE_VERTEX_COUNT ) 
void GetBokehVertex( CameraSettings settings, const float fVertexIndex, const vec2 vOrigin, const vec2 vDir, const float fSize, const float fCoC, const vec3 vCol, out OutVertex vertex )
{
  	float fInnerSize = fSize + fCoC;
  	float fGlowSize = 0.02;
  	float fOuterSize = fInnerSize + fGlowSize;
  
  	if ( fVertexIndex < HEXAGON_VERTEX_COUNT )
    {
  		GetHexagonVertex( settings, fVertexIndex, vOrigin, vDir, fInnerSize, vCol, vCol, vertex );
    }
  	else
    {
	  	vec3 vGlowCol = pow(vCol, vec3(0.5)) * 0.0001;    
      	if ( length( vGlowCol ) > 0.0000001 )
        {
  			GetHexagonOutlineVertex( settings, fVertexIndex - HEXAGON_VERTEX_COUNT, vOrigin, vDir, fInnerSize, fOuterSize, vGlowCol, vCol * 0.0, vertex );
        }
        else
        {
          	vertex.vPos.xy = vec2(0.0);
          	vertex.vColor.rgb = vec3(0.0);
        }
    }
}

float GetCoC( CameraSettings settings, float objectdistance )
{
  // http://http.developer.nvidia.com/GPUGems/gpugems_ch23.html

	return abs(settings.fAperture * (settings.fFocalLength * (objectdistance - settings.fPlaneInFocus)) /
          (objectdistance * (settings.fPlaneInFocus - settings.fFocalLength)));  
}


vec3 GetViewPos( CameraSettings settings, CameraPosition cameraPos, vec3 vWorldPos )
{
  	return (vWorldPos - cameraPos.vPosition) * cameraPos.mRotation;
}

vec2 GetScreenPos( CameraSettings settings, vec3 vViewPos )
{  
  	return vViewPos.xy * settings.fFocalLength * 5.0 / vViewPos.z;
}

CameraSettings GetCameraSettings( CameraPosition cameraPosition )
{
  	CameraSettings settings;
  
  	float aVal = sin(time * 0.25) * 0.5 + 0.5;
  	aVal = aVal * aVal;
  	settings.fAperture = aVal * 2.9 + 0.1;
  	float fVal = sin(time * 0.123) * 0.5 + 0.5;
  	settings.fFocalLength = 0.2 + 0.2 * fVal;
  	settings.fPlaneInFocus = length(cameraPosition.vTarget - cameraPosition.vPosition);
  
  	float oldAVal = sin((time - 0.5) * 0.25) * 0.5 + 0.5;
  	oldAVal = oldAVal * oldAVal;
  
	settings.fExposure = 3.0 + oldAVal *3.0;

  	return settings;
}

struct LightInfo
{
	vec3 vWorldPos;
  	float fRadius;
  	vec3 vColor;
};
  
  
vec2 SolveQuadratic( float a, float b, float c )
{
  float d = sqrt( b * b - 4.0 * a * c );
  vec2 dV = vec2( d, -d );
  return (-b + dV) / (2.0 * a);
}


vec3 BounceParticle( vec3 vOrigin, vec3 vInitialVel, float fGravity, float fFloorHeight, float fTime )
{
  	vec3 u = vInitialVel;
  	vec3 a = vec3(0.0, fGravity, 0.0);
  	vec3 vPos = vOrigin;

  	float t = fTime;
    	  	
  	for( int iBounce=0; iBounce < 3; iBounce++)
    {
      // When will we hit the ground?
      vec2 q = SolveQuadratic( 0.5 * a.y, u.y, -fFloorHeight + vPos.y);
      float tInt = max( q.x, q.y );
      tInt -= 0.0001;
      

      if ( t < tInt )
      {
	     vPos += u * t + 0.5 * a * t * t;
         break;
      }
      else
      {        
          // Calculate velocity at intersect time
          vec3 v = u + a * tInt;

          // step to intersect time
          vPos += u * tInt + 0.5 * a * tInt * tInt;
       	  u = v;
        
          // bounce
          u.y = -u.y * 0.3;
          u.xz *= 0.6;

          t -= tInt;
      }
    }

  	return vPos;
}

float fFloorHeight = 0.0;

LightInfo Fountain( const in float fLightIndex, const in vec3 vPos, float fTime, vec3 vCol, float fSpread )
{
    float fParticleLifetime = 1.5;
  	LightInfo lightInfo;
  
  	float h = Hash( fLightIndex + 12.0 );
  	vec3 h3 = Hash3( fLightIndex + 13.0 );
  
  	float fAngle = fLightIndex;
  
  	vec3 vInitialVel = (normalize(h3 * 2.0 - 1.0) * fSpread + vec3( 0.0, 10.0 - fSpread * 1.3, 0.0 )) * (0.4 + h * 0.4);
  	vec3 vOrigin = vPos + vec3( 0.0, fFloorHeight + 0.1, 0.0 ) + vInitialVel * 0.1;
  	lightInfo.vWorldPos = BounceParticle( vOrigin, vInitialVel, -9.81, fFloorHeight, fTime );

    
  	lightInfo.fRadius = 0.01;  
//  	lightInfo.vColor = vec3(1.0, 0.4, 0.1);
  	lightInfo.vColor = vCol;
       	lightInfo.vColor *= clamp( 1.0 - fTime + fParticleLifetime - 1.0, 0.0, 1.0);
	return lightInfo;  
}

LightInfo CatherineWheel( const in float fLightIndex, const in vec3 vPos, float fSequenceStart, float fSpawnTime, float fParticleT, vec3 vCol )
{
    	float h = Hash( fLightIndex + 4.0 );

	    float fParticleLifetime = 0.3 + h *0.5;
 	LightInfo lightInfo;

  	vec3 h3 = Hash3( fLightIndex + 12.0 );
  	float t = fSpawnTime - fSequenceStart;
  	if( t < 5.0 ) t = t * t;
  	else t = t * 5.0 + 5.0 * 5.0;
  	
  	float fSpawnAngle = t * 5.0;
  
  	if ( h > 0.5 )
    {
      fSpawnAngle += radians( 180.0 );
    }
  
  	mat3 m = RotMatrixZ(fSpawnAngle);
  
  	vec3 vInitialVel = vec3(-3.0, 0.0, 0.0 ) + h3 * 0.5;
  	vInitialVel = vInitialVel * m;
  	vec3 vOffset = vec3( 0.0, 0.03, 0.0 * m);
  	vec3 vOrigin = vPos + vOffset + vInitialVel * 0.1;
  	lightInfo.vWorldPos = BounceParticle( vOrigin, vInitialVel, -9.81, fFloorHeight, fParticleT );

    
  	lightInfo.fRadius = 0.01;  
//  	lightInfo.vColor = vec3(1.0, 0.4, 0.1);
  	lightInfo.vColor = vCol;
       	lightInfo.vColor *= clamp( 1.0 - fParticleT + fParticleLifetime - 1.0, 0.0, 1.0);
	return lightInfo;  
}


struct SequenceInfo
{
  	float fSequenceSet;
  	float fSequenceSetLength;
  
  	float fSequenceIndex;
  	float fSequenceStartTime;
  
  	float fSequenceSeed;
  	vec3 vSequenceHash;
  
  	vec3 vCol;
  
  	float fType;
  	vec3 vPos;
  	vec3 vTarget;
};
  
SequenceInfo GetSequenceInfo( float fSetIndex, float fTime )
{
  	SequenceInfo sequenceInfo;

  		float fSequenceSetCount = 2.0;
  	sequenceInfo.fSequenceSet = mod(fSetIndex, fSequenceSetCount);

  		float sh = Hash( sequenceInfo.fSequenceSet );
  		float fSequenceSetLength = 10.0 + sh * 5.0;
  

  		sequenceInfo.fSequenceIndex = floor( fTime / fSequenceSetLength );
  		sequenceInfo.fSequenceStartTime = (sequenceInfo.fSequenceIndex * fSequenceSetLength);
  
  		sequenceInfo.fSequenceSeed = sequenceInfo.fSequenceIndex + sequenceInfo.fSequenceSet * 12.3;
  		sequenceInfo.vSequenceHash = Hash3(sequenceInfo.fSequenceSeed);

  		float ch = Hash( sequenceInfo.fSequenceSeed * 2.34 );
  		sequenceInfo.vCol =  vec3(1.0, 0.4, 0.1);
  
  		if( ch < 0.25 )
        {
          sequenceInfo.vCol =  vec3(1.0, 0.08, 0.08);
        }
  		else if( ch < 0.5 )
        {
          sequenceInfo.vCol =  vec3(0.08, 0.08, 1.0);
        }
  		else if( ch < 0.75 )
        {
          sequenceInfo.vCol =  vec3(0.08, 1.0, 0.08 );
        }
  
  
    	if ( sequenceInfo.vSequenceHash.x < 0.7)
        {
  			sequenceInfo.vPos = vec3(0.0);
	  		sequenceInfo.vPos.xz = sequenceInfo.vSequenceHash.yz * 6.0 - 3.0;
	  		sequenceInfo.fType = 0.0;
          	sequenceInfo.vTarget = sequenceInfo.vPos;
          	sequenceInfo.vTarget.y = 1.5;
        }
  		else
        {
          	sequenceInfo.vPos = vec3(0.0, 2.5, 7.0);
	  		sequenceInfo.vPos += (sequenceInfo.vSequenceHash.xyz * 2.0 - 1.0) * vec3(5.0, 1.5, 3.0);
	  		sequenceInfo.fType = 1.0;
          	sequenceInfo.vTarget = sequenceInfo.vPos;
        }  
  
  	return sequenceInfo;
}

LightInfo GetFireworkSparkInfo( in float fLightIndex, float fTime, float fDeltaTime, vec3 h3 )
{      
	    float fParticleLifetime = 1.5;
      	float fParticleSpawnTime = (floor( (fTime / fParticleLifetime) + h3.x) - h3.x) * fParticleLifetime;
      	float fParticleEndTime = fParticleSpawnTime + fParticleLifetime;
      	float fParticleGlobalT = fTime - fParticleSpawnTime;
      	float fParticleT = mod( fParticleGlobalT, fParticleLifetime ) + fDeltaTime;
  
  		SequenceInfo sequenceInfo = GetSequenceInfo( fLightIndex, fParticleSpawnTime );
  
      	LightInfo lightInfo;
  
  		if ( sequenceInfo.fType < 0.5)
        {
          	float fSpread = fract( sequenceInfo.vSequenceHash.z + sequenceInfo.vSequenceHash.y ) + 1.0;
	  		lightInfo = Fountain( fLightIndex, sequenceInfo.vPos, fParticleT, sequenceInfo.vCol, fSpread );
        }
  		else
        {
          	lightInfo = CatherineWheel( fLightIndex, sequenceInfo.vPos, sequenceInfo.fSequenceStartTime, fParticleSpawnTime, fParticleT, sequenceInfo.vCol );
        }      
        
        return lightInfo;        
}

LightInfo GetLightInfo( const in float fLightIndex, float fTime, float fDeltaTime, CameraPosition cameraPos )
{
  	LightInfo lightInfo;

  	//float h = Hash( fLightIndex );
  	vec3 h3 = Hash3(fLightIndex);

  	float kHangingLightCount = 32.0;
  	float kHangingLightMax = 0.0 + kHangingLightCount;
  
  	float kStarCount = 0.0;
  	float kStarMax = kHangingLightMax + kStarCount;
  	
  	float kDirtCount = 16.0;
  	float kDirtMax = kStarMax + kDirtCount;

  	float kStreetLightCount = 64.0;
  	float kStreetLightMax = kDirtMax + kStreetLightCount;
  
  	float kGardenLightCount = 16.0;
  	float kGardenLightMax = kStreetLightMax + kGardenLightCount;

  	if( fLightIndex < kHangingLightMax )
  	{
  	// hanging lights
    	lightInfo.vWorldPos.x = ((fLightIndex / 10.0) * 2.0 - 1.0) * 3.0;
    	lightInfo.vWorldPos.y = 2.0 + -abs( cos( fLightIndex * 0.4 ) * 0.8 ); 
    	lightInfo.vWorldPos.z = 20.0;
  		lightInfo.vColor = vec3(0.01) * 0.5;
      	float fColIndex = mod(fLightIndex, 3.0);
      	if ( fColIndex == 0.0 ) lightInfo.vColor.x = 1.0;
      	if ( fColIndex == 1.0 ) lightInfo.vColor.y = 1.0;
      	if ( fColIndex == 2.0 ) lightInfo.vColor.z = 1.0;
	      lightInfo.vColor *= 0.05;
  		//lightInfo.vColor = normalize(vec3(sin(fLightIndex) * .5 + 0.5, sin(fLightIndex * 3.45) * .5 + 0.5, sin(fLightIndex * 4.56) * .5 + 0.5)) * 0.5;
    
  		lightInfo.fRadius = 0.05;
	}
  	else
  	if( fLightIndex < kStarMax )
  	{
      // stars
    	lightInfo.vWorldPos = normalize( h3 * 2.0 - 1.0 ) * 5000.0;
    	lightInfo.vWorldPos.y = abs(lightInfo.vWorldPos.y);
  		lightInfo.vColor = vec3(0.01);
  		lightInfo.fRadius = 0.001;
    }
  	else
  	if( fLightIndex < kDirtMax )
  	{
      // lens dirt
    	lightInfo.vWorldPos.xy = (Hash3(fLightIndex).xy * 2.0 - 1.0);
      	lightInfo.vWorldPos.xy = normalize(lightInfo.vWorldPos.xy) * pow( length(lightInfo.vWorldPos.xy), 0.3 ) * 0.35;
	    lightInfo.vWorldPos.y *= resolution.y / resolution.x;
    	lightInfo.vWorldPos.z = 0.3;
      	vec3 vOffset = cameraPos.mRotation * lightInfo.vWorldPos;
      	lightInfo.vWorldPos = vOffset + cameraPos.vPosition;
  		lightInfo.vColor = vec3(0.2, 0.18, 0.1) * abs( dot(normalize(vOffset), vec3(0.0, 0.0, 1.0)) ) * 10.0;
  		lightInfo.fRadius = 0.0001;
    }
  	else
  // street lights
  	if( fLightIndex < kStreetLightMax )
  	{
      	lightInfo.vWorldPos.xz = (h3.xy * 2.0 - 1.0) * 500.0;
    	lightInfo.vWorldPos.y = 10.0; 
  		lightInfo.vColor = vec3(1.0, 0.3, 0.01) * 0.5;
    
  		lightInfo.fRadius = 0.2;
	}
  	else if( fLightIndex < kGardenLightMax )
  	{
    	lightInfo.vWorldPos.y = 0.05 + h3.y * 0.5; 
      	vec2 vOffset = (h3.xz * 2.0 - 1.0);
      	lightInfo.vWorldPos.xz = vOffset * 50.0 + normalize( vOffset ) * 10.0;
  		lightInfo.vColor = sin(h3 * 10.0 + vec3(0.1, 0.2, 0.3)) * 0.5 + 0.5;
      	lightInfo.vColor = normalize(lightInfo.vColor);
	    lightInfo.vColor *= 0.005;
    
  		lightInfo.fRadius = 0.05;
	}
  	else
    {
      	lightInfo = GetFireworkSparkInfo( fLightIndex, fTime, fDeltaTime, h3 );
    }
     

  	return lightInfo;
}


vec3 GetCameraTarget( float fTime )
{
  	//return vec3(0.0, 1.8, 0.0);

  	float fInterval = 8.0;
  
  	float t0 = floor(fTime / fInterval) * fInterval; 
  	float t1 = (floor(fTime / fInterval+ 1.0) ) * fInterval; 
  
  	SequenceInfo inf0 = GetSequenceInfo( 0.0, t0 );
  	SequenceInfo inf1 = GetSequenceInfo( 0.0, t1 );
  
  	float fBlend = (fTime - t0) / fInterval;
  
  	fBlend = smoothstep( 0.0, 1.0, fBlend);
  
  	return mix( inf0.vTarget, inf1.vTarget, fBlend );
}

CameraPosition GetCameraPosition( float fTime, vec2 vTouch )
{
  	CameraPosition cameraPos;
  
  	if(  (vTouch.y > 0.9) && (vTouch.x > -0.83)  && (vTouch.x < -0.80) )
    {	
      	vTouch.xy = vec2(0.0);
    }
  
  	cameraPos.vTarget = GetCameraTarget( fTime );
   
  	cameraPos.vPosition += cameraPos.vTarget;
  	
  	cameraPos.vPosition = vec3( sin(fTime * 0.2) * 5.0, 2.0, -6.0 + sin(fTime * 0.0567) * 3.0);
  	cameraPos.vUp = vec3( 0.0, 1.0, 0.0 );
  
  	GetMatrixFromZY( normalize(cameraPos.vTarget - cameraPos.vPosition), cameraPos.vUp, cameraPos.mRotation );
  
  	vec3 vRot = vec3( vTouch.y * 0.5,  vTouch.x  * 0.5, 0.0 );
  
#ifdef SHAKY_CAM
	vRot += Noise23( cameraPos.vPosition.xz * 4.0 ) * vec3( 0.05, 0.03, 0.01 ); //shaky cam
#endif
  
  	cameraPos.mRotation = cameraPos.mRotation * RotMatrixZ(vRot.z) * RotMatrixY(vRot.y) * RotMatrixX( vRot.x ) ; 
  
  	return cameraPos;
}

void main() 
{
  float fVertexIndex = gl_VertexID;

  vec4 touch1 = texture2D(touch, vec2(0.0, 0.0));
  vec4 touch2 = texture2D(touch, vec2(0.0, 0.01));  

	float fShutterSpeed = 1.0 / 60.0;
  
  CameraPosition cameraPos = GetCameraPosition( time, touch1.xy );
  CameraPosition lastCameraPos = GetCameraPosition( time - fShutterSpeed, touch2.xy );

  CameraSettings cameraSettings = GetCameraSettings( cameraPos );

  OutVertex vertex;

  float fBokehIndex = floor( fVertexIndex / BOKEH_VERTEX_COUNT );
  
  LightInfo lightInfo = GetLightInfo( fBokehIndex, time, 0.0, cameraPos );
  LightInfo prevLightInfo = GetLightInfo( fBokehIndex, time, -fShutterSpeed, lastCameraPos );
  
  vec3 vViewPos = GetViewPos( cameraSettings, cameraPos, lightInfo.vWorldPos );
  vec3 vLastViewPos = GetViewPos( cameraSettings, lastCameraPos, prevLightInfo.vWorldPos );

  vec2 vScreenPos = GetScreenPos( cameraSettings, vViewPos );
  vec2 vLastScreenPos = GetScreenPos( cameraSettings, vLastViewPos );  

  float fScreenSize = GetScreenPos( cameraSettings, vec3( lightInfo.fRadius, lightInfo.fRadius, vViewPos.z ) ).x;
  
  vec2 vOrigin = vScreenPos.xy;
  vec2 vDir = vLastScreenPos.xy - vScreenPos.xy;
  
  float fCoC = GetCoC( cameraSettings, vViewPos.z );

  vec3 vCol = lightInfo.vColor;

  float fSize = fCoC + fScreenSize;
  vCol *= fScreenSize * fScreenSize * 3.14 / (length( vDir ) * fSize + fSize * fSize * 3.14);
  
  float fBokehVertexIndex = mod( fVertexIndex, BOKEH_VERTEX_COUNT );
  GetBokehVertex( cameraSettings, fBokehVertexIndex, vOrigin, vDir, fScreenSize, fCoC, vCol, vertex );
  
  vertex.vPos.y *= resolution.x / resolution.y;
  
  gl_Position = vec4(vertex.vPos.x, vertex.vPos.y, 1.0 / gl_VertexID, 1);
  float fFinalExposure = cameraSettings.fExposure / (cameraSettings.fAperture * cameraSettings.fAperture);
  v_color.rgb = 1.0 - exp2( vertex.vColor * -fFinalExposure );
  v_color.rgb = pow( v_color.rgb, vec3(1.0 / 2.2) );
  v_color.a = 0.0;
  
  float fNearClip = 0.25;
  if ( vViewPos.z <= fNearClip || vLastViewPos.z <= fNearClip)
  {
    gl_Position = vec4(0.0);
    v_color = vec4(0.0);
  }
    
}
