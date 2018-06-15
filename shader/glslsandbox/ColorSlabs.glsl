{"code": "#ifdef GL_ES\nprecision mediump float;\n#endif\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\n\nvarying vec2 surfacePosition;\n\n#define PI 3.14159265359\n\n#define SCALE 8.\n\n#define CORNER 16.\n\nvec3 hsv2rgb(vec3 c) {\n    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);\n    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);\n    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);\n}\n\nvoid main( void ) {\n\tvec2 position = surfacePosition * SCALE;\n\tposition += position*sin(time)/10.;\n\tposition.y += time;\n\tposition.x += mouse.x*8.0;\n\tvec2 realPos = ( gl_FragCoord.xy / resolution.xy) - 0.5;\n\trealPos.x *= resolution.x / resolution.y;\n\t\n\tvec2 mousePos = (mouse) - 0.5;\n\tmousePos.x *= resolution.x / resolution.y;\n\tvec3 light = vec3((mousePos - realPos), 0.5);\n\n\tvec3 normal = normalize(vec3(tan(position.x * PI), tan(position.y * PI), CORNER));\n\t\n\tfloat bright = dot(normal, normalize(light));\n\tbright = pow(bright, 1.);\n\t//bright *= step(length(position), 1.);\n\t\n\tvec3 color = hsv2rgb(vec3((floor(position.x + 0.5) + time)/SCALE, 1., 1.)) * bright;\n\t\n\tfloat rnd = fract(cos(floor(position.x + 10.5)*floor(position.y+ .5))*123.321);\n\t\n\t\n\tvec3 heif = normalize(light + vec3(0., 0., 1.));\n\t\n\tvec3 spec = vec3(pow(dot(heif, normal), 96.));\n\t\n\tcolor += spec;\n\n\t//gl_FragColor = vec4( vec3( color, color * 0.5, sin( color + time / 3.0 ) * 0.75 ), 1.0 );\n\tgl_FragColor = vec4(color, 1.);\n\n\tif (rnd > mouse.x) gl_FragColor = vec4(vec3(0), 1.);\n}", "user": "8e35c05", "parent": "/e#25704.1", "id": "25740.2"}