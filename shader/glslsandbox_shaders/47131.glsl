{"code": "/*\n * Original shader from: https://www.shadertoy.com/view/ls3BWf\n */\n\n#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// glslsandbox uniforms\nuniform float time;\nuniform vec2 resolution;\n\n// shadertoy globals\nfloat iTime;\nvec3  iResolution;\n\n// --------[ Original ShaderToy begins here ]---------- //\nconst float MIN_DIST = 0.0;\nconst float MAX_DIST = 15.0;\nconst float EPSILON = 0.0001;\nconst float PI = 3.14159;\n\n\nmat4 rotateY(float theta) {\n    float c = cos(theta);\n    float s = sin(theta);\n\n    return mat4(\n        vec4(c, 0, s, 0),\n        vec4(0, 1, 0, 0),\n        vec4(-s, 0, c, 0),\n        vec4(0, 0, 0, 1)\n    );\n}\n\nmat4 rotateX(float theta) {\n    float c = cos(theta);\n    float s = sin(theta);\n\n    return mat4(\n        vec4(1, 0, 0, 0),\n        vec4(0, c, -s, 0),\n        vec4(0, s, c, 0),\n        vec4(0, 0, 0, 1)\n    );\n}\n\nmat4 rotateZ(float a ) {\n    float c = cos( a );\n    float s = sin( a );\n    return mat4(\n        c,-s, 0, 0,\n        s, c, 0, 0,\n        0, 0, 1, 0,\n        0, 0, 0, 1\n    );\n}\n\nmat4 scale(float a ) {\n    return mat4(\n        a,0, 0, 0,\n        0, a, 0, 0,\n        0, 0, a, 0,\n        0, 0, 0, 1\n    );\n}\n\nfloat sdSphere( vec3 p, float s)\n{\n  \n  return length(p)-s;\n}\n\n\nfloat rand_1_05(in vec2 uv)\n{\n    float noise = (fract(sin(dot(uv ,vec2(12.9898,78.233)*2.0)) * 43758.5453));\n    return noise;\n}\t\n\n\n// Voronoi from iq\nvec3 Voronoi( in vec3 x )\n{\n    x.y *= 15. * (1.+ cos(iTime)/15.); // scale of my voronoi\n    x.x *= 15. * (1.- sin(iTime)/10.); \n    \n    vec3 p = floor( x );\n    vec3 f = fract( x );\n\n\tfloat id = 1.;\n    vec2 res = vec2( .8 );\n    for( int k=-1; k<=1; k++ )\n    for( int j=-1; j<=1; j++ )\n    for( int i=-1; i<=1; i++ )\n    {\n        vec3 b = vec3( float(i), float(j), float(k) );\n        vec3 r = vec3( b ) - f + rand_1_05( 10.*vec2(p + b) );\n\n\n        float d = dot( r, r ) ;\n\n        if( d < res.x )\n        {\n\t\t\tid = dot( p+b, vec3(1.0,57.0,113.0 ) );\n            \n            res = vec2( d, res.x );\n\n            \n        }\n        else if( d < res.y )\n        {\n            res.y = d;\n        }\n    }\n\n    return vec3( res, abs(id));\n}\n\n\n// Sphere uv mapping from aiekick : https://www.shadertoy.com/view/MtS3DD\nvec3 sphere_map(vec3 p)\n{\n    vec2 uv;\n    uv.x = 1. + atan(p.z, p.x) / (2.*3.14159);\n    uv.y = 1. - asin(p.y) / 3.14159;\n    return Voronoi(vec3(uv,0.0));\n}\n\n\nfloat map(vec3 originPos)\n{\n    vec3 ret = sphere_map(normalize(originPos));\n\treturn length(originPos) - 1. - .5*ret.x * (-.5) * (.5+sin(iTime)/5.) ; //*(sin(iTime)/2.-2.);  // peaks variation   \n}\n\nfloat trace(vec3 o, vec3 r)\n{\n float t= 0.0;\n    for(int i=0; i< 45; ++i) // for number of iteration\n    {\n    \tvec3 p = o + r*t; // until we find intersection\n        float d = map(p);\n        if (d < EPSILON) break;\n        t += d ; // advancing on ray\n    }\n    return t;\n        \n}\n\nfloat applyFog( float b ) \n{\n    return pow(1.0 / (1.0 + b), 1.0);;\n}\n\nvec3 estimateNormal(vec3 p) \n{ float d = map(p); \n return normalize(vec3( map(vec3(p.x + EPSILON, p.y, p.z)), map(vec3(p.x, p.y + EPSILON, p.z)), map(vec3(p.x, p.y, p.z + EPSILON)) ) - d); \n} \n\nvoid mainImage( out vec4 fragColor, in vec2 fragCoord )\n{\n    // Normalized pixel coordinates (from 0 to 1)\n    vec2 uv = fragCoord/iResolution.xy;\n    uv = uv * 2.0 - 1.0;\n\tuv.x *= iResolution.x/iResolution.y;\n\n    vec3 ro = vec3( 0.0, 0.0, -3.0 );      \n    vec3 rd = normalize(vec3(uv,3.0)) ; // normalized so it does not poke geometry close to camera\n    float t = trace(ro, rd); // distance\n\tvec3 intersection = ro + rd * t;     \n    vec3 vNormal = estimateNormal(intersection);\n    \n    vec3 col = vec3(0.2);\n\tif(t < MAX_DIST)\n    {\n        // Determine light direction \n        vec3 ld = intersection - ro; // where the camera is (?)        \n        ld = normalize(ld);\n\n        // Spec\n        float spec = pow(max(dot( reflect(-ld, vNormal), -rd), 0.), 16.); \n      \tcol *= sqrt( spec  * vec3(10.,10.0,10.0));\n        col += sphere_map(normalize(intersection)) * vec3(1.,0.001,0.00005) * (1.+sin(iTime)/2.);\n\n    }\n    else // background\n    {\n     \tcol = vec3(0.2);\n\n\n        vec3 light_color = vec3(0.9, 0., 0.1);\n        float light = .0;\n\n        light = (1.+cos(iTime)/10.)*0.1 / distance(normalize(uv)*(1.+cos(iTime)/5.)*0.68, uv);\n\n        col+= light * light_color;\n    }\n\t\n\t\n\tcol = sqrt( col ) ;\n    \n\n    // Output to screen\n    fragColor = vec4(col,1.0);\n}\n// --------[ Original ShaderToy ends here ]---------- //\n\nvoid main(void)\n{\n    iTime = time;\n    iResolution = vec3(resolution, 0.0);\n\n    mainImage(gl_FragColor, gl_FragCoord.xy);\n}", "user": "f251140", "parent": null, "id": "47131.0"}