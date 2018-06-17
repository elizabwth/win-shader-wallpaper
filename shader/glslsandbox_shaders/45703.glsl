{"code": "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#define PI 3.14159\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\n\nfloat myround(float v)\n{\n\tif(v - floor(v) >= .5) return floor(v)+1.0;\n\telse return floor(v);\n\n}\n\nvec2 myround(vec2 v)\n{\n\tvec2 ret = vec2(0.0);\n\tif(v.x - floor(v.x) >= 0.5) ret.x = floor(v.x)+1.0;\n\telse ret.x = floor(v.x);\n\tif(v.y - floor(v.y) >= 0.5) ret.y = floor(v.y)+1.0;\n\telse ret.y = floor(v.y);\n\treturn ret;\n}\n\nfloat triwave(float x)\n{\n\treturn 1.0-4.0*abs(0.5-fract(0.5*x + 0.25));\n}\n\n//from #3611.0\n\nfloat rand(vec2 co){\n\tfloat t = mod(time,64.0);\n    return fract(sin(dot(co.xy ,vec2(1.9898,7.233))) * t*t);\n}\n\n//from http://github.prideout.net/barrel-distortion/\n\nfloat BarrelPower = 1.085;\nvec2 Distort(vec2 p)\n{\n    float theta  = atan(p.y, p.x);\n    float radius = length(p);\n    radius = pow(radius, BarrelPower);\n    p.x = radius * cos(theta);\n    p.y = radius * sin(theta);\n    return 0.5 * (p + 1.0);\n}\n//------------------------------ modded http://glslsandbox.com/e#45293.0\nvec3 shader( vec2 p, vec2 resolution ) {\n\n\tvec2 position = ( p / resolution.xy ) ;\n\tfloat t = time;\n\tfloat b = 0.0;\n\tfloat g = 0.0;\n\tfloat r = 0.0;\n\t\n\tfloat yorigin = 1.0 + 0.1*(tan(sin(position.x*40.0+1.0*(fract(t / 2.0)) * 2.5 * 20.)));\n\t\n\tfloat dist = ( 20.0*abs(yorigin - position.y));\n\t\n\tb = (0.02 + 0.2  + 0.4)/dist;//+ -(position.x - 0.7);\n\tg = (0.02 + 0.0013*(1000.))/dist;// + (position.x - 0.3);\n\tr = (0.02 + .005 *(1000.))/dist + sin(position.x - 1.0 );\n\treturn vec3( r, g, b);\n//-------------------\n}\n\nfloat pixelsize = 6.0;\n\nvoid main( void ) {\n\n\tvec2 position = ( gl_FragCoord.xy);\n\t\n\tvec3 color = vec3(0.0);\n\t\n\tvec2 dposition = Distort(position/resolution-0.5)*(resolution*2.0);\n\t\n\tvec2 rposition = myround(((dposition-(pixelsize/2.0))/pixelsize));\n\t\n\t\n\tcolor = vec3(shader(rposition,resolution/pixelsize));\n\t\n\t//color = clamp(color,0.0625,1.0);\n\t\n\tcolor *= (rand(rposition)*0.25+0.75);\n\t\n\t//color *= abs(sin(rposition.y*8.0+(time*16.0))*0.25+0.75);\n\t\n\tcolor *= vec3(clamp( abs(triwave(dposition.x/pixelsize))*3.0 , 0.0 , 1.0 ));\n\tcolor *= vec3(clamp( abs(triwave(dposition.y/pixelsize))*3.0 , 0.0 , 1.0 ));\n\t\n\tfloat darkness = sin((position.x/resolution.x)*PI)*sin((position.y/resolution.y)*PI);\n\t\n\tcolor *= vec3(clamp( darkness*4.0 ,0.0 ,1.0 ));\n\t\n\tgl_FragColor = vec4( color, 1.0 );\n\n}", "user": "ff8d18c", "parent": "/e#3615.4", "id": "45703.10"}