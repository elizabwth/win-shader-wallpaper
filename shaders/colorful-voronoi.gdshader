shader_type canvas_item;
// Colorful Voronoi
// By: Brandon Fogerty
// bfogerty at gmail dot com
// xdpixel.com
//#ifdef GL_ES
//precision mediump float;
//#endif

//uniform float time;
//uniform vec2 mouse;
//uniform vec2 resolution;

vec2 hash(vec2 p) {
	mat2 m = mat2(vec2(13.85, 47.77), vec2(99.41, 88.48));

    return fract(sin(m*p) * 46738.29);
}

float voronoi(vec2 p)
{
    vec2 g = floor(p);
    vec2 f = fract(p);

    float distanceToClosestFeaturePoint = 1.0;
    for (float y = -1.0; y <= 1.0; y++) {
        for (float x = -1.0; x <= 1.0; x++) {
            vec2 latticePoint = vec2(x, y);
            float currentDistance = distance(latticePoint + hash(g+latticePoint), f);
            distanceToClosestFeaturePoint = min(distanceToClosestFeaturePoint, currentDistance);
        }
    }

    return distanceToClosestFeaturePoint;
}

void fragment() {
	vec2 resolution = (1.0 / SCREEN_PIXEL_SIZE);
    vec2 uv = ( FRAGCOORD.xy / resolution.xy ) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    float offset = voronoi(uv*10.0 + vec2(TIME));
    float t = 1.0/abs(((uv.x + sin(uv.y + TIME)) + offset) * 30.0);

    float r = voronoi( uv * 1.0 ) * 10.0;
    vec3 finalColor = vec3(10.0 * uv.y, 2.0, 1.0 * r) * t;
    
    COLOR = vec4(finalColor, 1.0 );
}