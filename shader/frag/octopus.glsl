#extension GL_OES_standard_derivatives : enable

#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 resolution;

void mainImage( out vec4, in vec2 );

void main( void )
{
    mainImage( gl_FragColor, gl_FragCoord.xy );
}

// ------------------------------------------------------------

#define iGlobalTime time
// https://www.shadertoy.com/view/MdsBz2
#define iResolution resolution

// "Octopus!" by Krzysztof Narkowicz @knarkowicz
// License: Public Domain

const float MATH_PI = float( 3.14159265359 );

float saturate( float x )
{
    return clamp( x, 0.0, 1.0 );
}

float Smooth( float x )
{
    return smoothstep( 0.0, 1.0, saturate( x ) );   
}

float Sphere( vec3 p, float s )
{
    return length( p ) - s;
}

float Capsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float Union( float a, float b )
{
    return min( a, b );
}

float UnionRound( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 * ( b - a ) / k, 0.0, 1.0 );
    return mix( b, a, h ) - k * h * ( 1.0 - h );
}

float SubstractRound( float a, float b, float r ) 
{
    vec2 u = max( vec2( r + a, r - b ), vec2( 0.0, 0.0 ) );
    return min( -r, max( a, -b ) ) + length( u );
}

float Displace( float scale, float ampl, vec3 p )
{
    p *= ampl;
    return scale * sin( p.x ) * sin( p.y ) * sin( p.z );
}

float RepeatAngle( inout vec2 p, float n ) 
{
    float angle = 2.0 * MATH_PI / n;
    float a = atan( p.y, p.x ) + angle / 2.0;
    float r = length( p );
    float c = floor( a / angle );
    a = mod( a, angle ) - angle / 2.;
    p = vec2( cos( a ), sin( a ) ) * r;
    return c;
}

void Rotate( inout vec2 p, float a ) 
{
    p = cos( a ) * p + sin( a ) * vec2( p.y, -p.x );
}

float Tentacle( vec3 p )
{
    p.y += 0.3;
    
    float scale = 1.0 - 2.5 * saturate( abs( p.y ) * 0.25 );    
    
    p.x = abs( p.x );
    
    p -= vec3( 1.0, -0.5, 0.0 );
    Rotate( p.xy, 0.4 * MATH_PI );
    p.x -= sin( p.y * 5.0 + iGlobalTime * 1.6 ) * 0.05;
    
    float ret = Capsule( p, vec3( 0.0, -1000.0, 0.0 ), vec3( 0.0, 1000.0, 0.0 ), 0.25 * scale );

    p.z = abs( p.z );
    p.y = mod( p.y + 0.08, 0.16 ) - 0.08;
    p.z -= 0.12 * scale;
    float tent = Capsule( p, vec3( 0.0, 0.0, 0.0 ), vec3( -0.4 * scale, 0.0, 0.0 ), 0.1 * scale );
    
    float pores = Sphere( p - vec3( -0.4 * scale, 0.0, 0.0 ), mix( 0.04, 0.1, scale ) );
    tent = SubstractRound( tent, pores, 0.01 );
  
    ret = UnionRound( ret, tent, 0.05 * scale );
    return ret;
}

float Scene( vec3 p )
{   
    p.z += cos( p.y * 0.2 + iGlobalTime ) * 0.11;
    p.x += sin( p.y * 5.0 + iGlobalTime ) * 0.05;    
    p.y += sin( iGlobalTime * 0.51 ) * 0.1;
    
    Rotate( p.yz, 0.45 + sin( iGlobalTime * 0.53 ) * 0.11 );
    Rotate( p.xz, 0.12 + sin( iGlobalTime * 0.79 ) * 0.09 );
    
    vec3 t = p;
    RepeatAngle( t.xz, 8.0 );
    float ret = Tentacle( t );

    p.z += 0.2;
    p.x += 0.2;
        
    float body = Sphere( p - vec3( -0.0, -0.3, 0.0 ), 0.6 );
    
    t = p;    
    t.x *= 1.0 - t.y * 0.4;
    body = UnionRound( body, Sphere( t - vec3( -0.2, 0.5, 0.4 ), 0.8 ), 0.3 ); 
    
    body += Displace( 0.02, 10.0, p );
   
    ret = UnionRound( ret, body, 0.05 );   
    
    ret = SubstractRound( ret, Sphere( p - vec3( 0.1, -1.0, 0.2 ), 0.4 ), 0.1 );        
    
    return ret;
}

float CastRay( in vec3 ro, in vec3 rd )
{
    const float maxd = 10.0;
    
    float h = 1.0;
    float t = 0.0;
   
    for ( int i = 0; i < 50; ++i )
    {
        if ( h < 0.001 || t > maxd ) 
        {
            break;
        }
        
        h = Scene( ro + rd * t );
        t += h;
    }

    if ( t > maxd )
    {
        t = -1.0;
    }
    
    return t;
}

vec3 SceneNormal( in vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 normal = vec3(
        Scene( pos + eps.xyy ) - Scene( pos - eps.xyy ),
        Scene( pos + eps.yxy ) - Scene( pos - eps.yxy ),
        Scene( pos + eps.yyx ) - Scene( pos - eps.yyx ) );
    return normalize( normal );
}

vec3 WaterKeyColor  = vec3( 0.09, 0.92, 0.98 );
vec3 WaterFillColor = vec3( 0.1, 0.06, 0.28 );

vec3 Water( vec3 rayDir )
{
    Rotate( rayDir.xy, -0.2 ); 
    vec3 color = mix( WaterKeyColor, WaterFillColor, Smooth( -1.2 * rayDir.y + 0.5 ) );
    return color;
}

float Circle( vec2 p, float r )
{
    return ( length( p / r ) - 1.0 ) * r;
}

void BokehLayer( inout vec3 color, vec2 p, vec3 c, float radius )   
{    
    float wrap = 350.0;    
    if ( mod( floor( p.y / wrap + 0.5 ), 2.0 ) == 0.0 )
    {
        p.x += wrap * 0.5;
    }    
    
    vec2 p2 = mod( p + 0.5 * wrap, wrap ) - 0.5 * wrap;
    float sdf = Circle( p2, radius );
    color += c * ( 1.0 - Smooth( sdf * 0.01 ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x / iResolution.y;

    vec3 rayOrigin  = vec3( -0.5, -0.5, -4.0 );
    vec3 rayDir     = normalize( vec3( p.xy, 2.0 ) ); 

    vec3 background = Water( rayDir );
      
    p *= 400.0;
    Rotate( p, -0.2 );  
    BokehLayer( background, p + vec2( 125.0, -120.0 * iGlobalTime ), vec3( 0.1 ), 0.5 );
    BokehLayer( background, p * 1.5 + vec2( 546.0, -80.0 * iGlobalTime ), vec3( 0.07 ), 0.25 ); 
    BokehLayer( background, p * 2.3 + vec2( 45.0, -50.0 * iGlobalTime ), vec3( 0.03 ), 0.1 ); 

    vec3 color = background;
    float t = CastRay( rayOrigin, rayDir );
    if ( t > 0.0 )
    {        
        vec3 pos = rayOrigin + t * rayDir;
        vec3 normal = SceneNormal( pos );
        
        float specOcc = Smooth( 0.5 * length( pos - vec3( -0.1, -1.2, -0.2 ) ) );

  
        vec3 c0 = vec3( 0.95, 0.99, 0.43 );
        vec3 c1 = vec3( 0.67, 0.1, 0.05 );
        vec3 c2 = WaterFillColor;
        vec3 baseColor = normal.y > 0.0 ? mix( c1, c0, saturate( normal.y ) ) : mix( c1, c2, saturate( -normal.y ) );
                
        vec3 reflVec = reflect( rayDir, normal );        
        float fresnel = saturate( pow( 1.2 + dot( rayDir, normal ), 5.0 ) );
        color = 0.8 * baseColor + 0.6 * Water( reflVec ) * mix( 0.04, 1.0, fresnel * specOcc );

        float transparency = Smooth( 0.9 + dot( rayDir, normal ) );
        color = mix( color, background, transparency * specOcc );
    }
    
    float vignette = q.x * q.y * ( 1.0 - q.x ) * ( 1.0 - q.y );
    vignette = saturate( pow( 32.0 * vignette, 0.05 ) );
    color *= vignette;
        
    fragColor = vec4( color, 1.0 );
}