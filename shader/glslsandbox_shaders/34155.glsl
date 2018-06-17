{"code": "// Rolling ball. By David Hoskins, April 2014.\n// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.\n// https://www.shadertoy.com/view/lsfXz4\n\n// Uses https://www.shadertoy.com/view/Xsf3zX as base.\n\n#ifdef GL_ES\nprecision mediump float;\n#endif\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\n\nfloat PI  = 4.0*atan(1.0);\nvec3 sunLight  = normalize( vec3(  0.35, 0.2,  0.3 ) );\nvec3 cameraPos;\nvec3 camTar;\nvec3 sunColour = vec3(1.0, .6, .4);\nconst mat2 rotate2D = mat2(1.932, 1.623, -1.623, 1.952);\nfloat gTime = 0.0;\nvec2 ballRoll;\nfloat bounce;\n//#define MOD2 vec2(3.07965, 7.4235)\n#define MOD2 vec2(.16632,.17369)\n#define f(p) length(fract(p/70.) - .5)\n\n//--------------------------------------------------------------------------\n// Noise functions...\nfloat Hash( float p )\n{\n\tvec2 p2 = fract(vec2(p) / MOD2);\n    p2 += dot(p2.yx, p2.xy+19.19);\n\treturn fract(p2.x * p2.y);\n}\n\n//--------------------------------------------------------------------------\nfloat Hash(vec2 p)\n{\n\tp  = fract(p / MOD2);\n    p += dot(p.xy, p.yx+19.19);\n    return fract(p.x * p.y);\n}\n\n\n//--------------------------------------------------------------------------\nfloat Noise( in vec2 x )\n{\n    vec2 p = floor(x);\n    vec2 f = fract(x);\n    f = f*f*(3.0-2.0*f);\n    \n    float res = mix(mix( Hash(p), Hash(p+ vec2(1.0, 0.0)),f.x),\n                    mix( Hash(p+ vec2(.0, 1.0)), Hash(p+ vec2(1.0, 1.0)),f.x),f.y);\n    return res;\n}\n\n//--------------------------------------------------------------------------\nvec2 Rotate2(vec2 p, float a)\n{\n\tfloat si = sin(a);\n\tfloat co = cos(a);\n\treturn mat2(co, si, -si, co) * p;\n}\n\n\n\n//--------------------------------------------------------------------------\nvec2 Voronoi( in vec2 x )\n{\n\tvec2 p = floor( x );\n\tvec2 f = fract( x );\n\tfloat res=100.0,id;\n\tfor( int j=-1; j<=1; j++ )\n\tfor( int i=-1; i<=1; i++ )\n\t{\n\t\tvec2 b = vec2( float(i), float(j) );\n\t\tvec2 r = b - f  + Hash( p + b );\n\t\tfloat d = dot(r,r);\n\t\tif( d < res )\n\t\t{\n\t\t\tres = d;\n\t\t\tid  = Hash(p+b);\n\t\t}\t\t\t\n    }\n\treturn vec2(max(.4-sqrt(res), 0.0),id);\n}\n\n\n//--------------------------------------------------------------------------\nvec3 BallTexture( in vec3 n)\n{\n\tvec3 col = vec3(.5, 0.0, 0.0);\n\tcol= mix(col, vec3(.0, .6, 0.9), smoothstep(-0.05, -.04, n.y) * smoothstep(0.05, .04, n.y));\n\tfloat at = cos(atan(n.x, n.z) * 5.0)*(n.y*n.y);\n\tcol =mix(col, vec3(.7, .7, 0.0), smoothstep(0.3, .32, at));\n\treturn col * .8;\n}\n\n//--------------------------------------------------------------------------\nvec2 Terrain( in vec2 p)\n{\n\tfloat type = 0.0;\n\tvec2 pos = p*0.003;\n\tfloat w = 50.0;\n\tfloat f = .0;\n\tfor (int i = 0; i < 3; i++)\n\t{\n\t\tf += Noise(pos) * w;\n\t\tw = w * 0.62;\n\t\tpos *= 2.6;\n\t}\n\n\treturn vec2(f, type);\n}\n\n//--------------------------------------------------------------------------\nvec2 Map(in vec3 p)\n{\n\tvec2 h = Terrain(p.xz);\n    return vec2(p.y - h.x, h.y);\n}\n\n//--------------------------------------------------------------------------\nfloat FractalNoise(in vec2 xy)\n{\n\tfloat w = .7;\n\tfloat f = 0.0;\n\n\tfor (int i = 0; i < 3; i++)\n\t{\n\t\tf += Noise(xy) * w;\n\t\tw = w*0.6;\n\t\txy = 2.0 * xy;\n\t}\n\treturn f;\n}\n\n//--------------------------------------------------------------------------\n// Grab all sky information for a given ray from camera\nvec3 GetSky(in vec3 rd, bool doClouds)\n{\n\tfloat sunAmount = max( dot( rd, sunLight), 0.0 );\n\tfloat v = pow(1.0-max(rd.y,0.0),6.);\n\tvec3  sky = mix(vec3(.1, .2, .3), vec3(.32, .32, .32), v);\n\tsky = sky + sunColour * sunAmount * sunAmount * .25;\n\tsky = sky + sunColour * min(pow(sunAmount, 800.0)*1.5, .4);\n\t\n\tif (doClouds)\n\t{\n\t\tvec2 cl = rd.xz * (1.0/rd.y);\n\t\tv = FractalNoise(cl) * .3;\n\t\tsky = mix(sky, sunColour, v*v);\n\t}\n\n\treturn clamp(sky, 0.0, 1.0);\n}\n\n//--------------------------------------------------------------------------\n// Merge grass into the sky background for correct fog colouring...\nvec3 ApplyFog( in vec3  rgb, in float dis, in vec3 dir)\n{\n\tfloat fogAmount = clamp(dis*dis* 0.0000011, 0.0, 1.0);\n\treturn mix( rgb, GetSky(dir, false), fogAmount );\n}\n\n//--------------------------------------------------------------------------\nvec3 DE(vec3 p)\n{\n\tfloat base = Terrain(p.xz).x - 1.9;\n\tfloat height = Noise(p.xz*2.0)*.75 + Noise(p.xz)*.35 + Noise(p.xz*.5)*.2;\n\t//p.y += height;\n\n\tfloat y = p.y - base-height;\n\ty = y*y;\n\t\n\t// Move grass out of way of target (ball)...\n\tvec2 move = (p.xz-camTar.xz);\n\tfloat l = length(move);\n\tmove = (move * y) * smoothstep(15.0, -6.0, l)/ (bounce+1.0);\n\tp.xz -= move;\n\n\tvec2 ret = Voronoi((p.xz*2.5+sin(y*4.0+p.zx*3.23)*0.12+vec2(sin(time*2.3+0.5*p.z),sin(time*3.6+.5*p.x))*y*.5));\n\tfloat f = ret.x * .6 + y * .58;\n\treturn vec3( y - f*1.4, clamp(f * 1.5, 0.0, 1.0), ret.y);\n}\n\n//--------------------------------------------------------------------------\n// eiffie's code for calculating the aperture size for a given distance...\nfloat CircleOfConfusion(float t)\n{\n\treturn max(t * .04, (2.0 / resolution.y) * (1.0+t));\n}\n\n//--------------------------------------------------------------------------\nfloat Linstep(float a, float b, float t)\n{\n\treturn clamp((t-a)/(b-a),0.,1.);\n}\n\n//--------------------------------------------------------------------------\nfloat Sphere( in vec3 ro, in vec3 rd, in vec4 sph )\n{\n\tvec3 oc = ro - sph.xyz;\n\tfloat b = dot( oc, rd );\n\tfloat c = dot( oc, oc ) - sph.w*sph.w;\n\tfloat h = b*b - c;\n\tif( h<0.0 ) return -1.0;\n\treturn -b - sqrt( h );\n}\n\n//--------------------------------------------------------------------------\n// Calculate sun light...\nvoid DoLighting(inout vec3 mat, in vec3 normal, in float dis)\n{\n\tfloat h = dot(sunLight,normal);\n\tmat = mat * sunColour*(max(h, 0.0)+max((normal.y+.3) * .2, 0.0)+.1);\n}\n\n//--------------------------------------------------------------------------\nvec3 GrassOut(in vec3 rO, in vec3 rD, in vec3 mat, in vec3 normal, in float dist)\n{\n\tfloat d = -2.0;\n\t\n\t// Only calculate cCoC once is enough here...\n\tfloat rCoC = CircleOfConfusion(dist*.3);\n\tfloat alpha = 0.0;\n\t\n\tvec4 col = vec4(mat, 0.0);\n\n\tfor (int i = 0; i < 10; i++)\n\t{\n\t\tif (col.w > .99 || d > dist) break;\n\t\tvec3 p = rO + rD * d;\n\t\t\n\t\tvec3 ret = DE(p);\n\t\tret.x += .5 * rCoC;\n\n\t\tif (ret.x < rCoC)\n\t\t{\n\t\t\talpha = (1.0 - col.w) * Linstep(-rCoC, rCoC, -ret.x);//calculate the mix like cloud density\n\t\t\t\n\t\t\t// Mix material with white tips for grass...\n\t\t\tvec3 gra = mix(vec3(.0, .2, 0.0), vec3(.1, .4, min(pow(ret.z, 4.0)*35.0, .35)),\n\t\t\t\t\t\t   pow(ret.y, 9.0)*.7) * ret.y * .7;\n\t\t\tcol += vec4(gra * alpha, alpha);\n\t\t}\n\t\td += .02;\n\t}\n\t\n\tDoLighting(col.xyz, normal, dist);\n\t\n\tcol.xyz = mix(mat, col.xyz, col.w);\n\n\treturn col.xyz;\n}\n\n\n//--------------------------------------------------------------------------\nvec3 GrassBlades(in vec3 rO, in vec3 rD, in vec3 mat, in float dist)\n{\n\tfloat d = 0.0;\n\tfloat f;\n\t// Only calculate cCoC once is enough here...\n\tfloat rCoC = CircleOfConfusion(dist*.3);\n\tfloat alpha = 0.0;\n\t\n\tvec4 col = vec4(mat*0.15, 0.0);\n\n\tfor (int i = 0; i < 15; i++)\n\t{\n\t\tif (col.w > .99) break;\n\t\tvec3 p = rO + rD * d;\n\t\t\n\t\tvec3 ret = DE(p);\n\t\tret.x += .5 * rCoC;\n\n\t\tif (ret.x < rCoC)\n\t\t{\n\t\t\talpha = (1.0 - col.y) * Linstep(-rCoC, rCoC, -ret.x) * 2.0;//calculate the mix like cloud density\n\t\t\tf = clamp(ret.y, 0.0, 1.0);\n\t\t\t// Mix material with white tips for grass...\n\t\t\tvec3 gra = mix(mat, vec3(.2, .3, min(pow(ret.z, 14.0)*3.0, .3)), pow(ret.y,100.0)*.6 ) * ret.y;\n\t\t\tcol += vec4(gra * alpha, alpha);\n\t\t}\n\t\td += max(ret.x * .7, .02);\n\t}\n\tif(col.w < .2)col.xyz = vec3(0.1, .15, 0.05);\n\treturn col.xyz;\n}\n\n//--------------------------------------------------------------------------\nvec3 TerrainColour(vec3 pos, vec3 dir,  vec3 normal, float dis, float type)\n{\n\tvec3 mat;\n\tif (type == 0.0)\n\t{\n\t\t// Random colour...\n\t\tmat = mix(vec3(.0,.2,.0), vec3(.1,.3,.0), Noise(pos.xz*.025));\n\t\t// Random shadows...\n\t\tfloat t = FractalNoise(pos.xz * .1)+.5;\n\t\t// Do grass blade tracing...\n\t\tmat = GrassBlades(pos, dir, mat, dis) * t;\n\t\tDoLighting(mat, normal, dis);\n\t\tfloat f = Sphere( pos, sunLight, vec4(camTar, 10.0));\n\t\tif (f > 0.0)\n\t\t{\n\t\t\tmat *= clamp(f*.05, 0.4, 1.0);\n\t\t}\n\t}else\n\t{\n\t\t// Ball...\n\t\tvec3 nor = normalize(pos-camTar);\n\t\tvec3 spin = nor;\n\t\t\n\t\tspin.xz = Rotate2(spin.xz, ballRoll.y);\n\t\tspin.zy = Rotate2(spin.zy, ballRoll.x);\n\t\tspin.xy = Rotate2(spin.xy, .4);\n\t\t\n\t\tmat = BallTexture(spin);\n\t\tDoLighting(mat, nor, dis);\n\t\tvec3 ref = reflect(dir, nor);\n\t\tmat += sunColour * pow(max(dot(ref, sunLight), 0.0), 6.0) * .3;\n\t\t\n\t\tif (pos.y < Terrain(pos.xz).x+1.5)\n\t\t{\n\t\t\tmat = GrassOut(pos, dir, mat, normal, dis);\n\t\t}\n\t}\n\tmat = ApplyFog(mat, dis, dir);\n\treturn mat;\n}\n\n//--------------------------------------------------------------------------\n// Home in on the surface by dividing by two and split...\nfloat BinarySubdivision(in vec3 rO, in vec3 rD, float t, float oldT)\n{\n\tfloat halfwayT = 0.0;\n\tfor (int n = 0; n < 5; n++)\n\t{\n\t\thalfwayT = (oldT + t ) * .5;\n\t\tif (Map(rO + halfwayT*rD).x < .05)\n\t\t{\n\t\t\tt = halfwayT;\n\t\t}else\n\t\t{\n\t\t\toldT = halfwayT;\n\t\t}\n\t}\n\treturn t;\n}\n\n\n//--------------------------------------------------------------------------\nvec3 CameraPath( float t )\n{\n\t//t = time + t;\n    vec2 p = vec2(200.0 * sin(3.54*t), 200.0 * cos(3.54*t) );\n\treturn vec3(p.x+5.0,  0.0, -94.0+p.y);\n} \n\n//--------------------------------------------------------------------------\nbool Scene(in vec3 rO, in vec3 rD, inout float resT, inout float type )\n{\n    float t = 5.;\n\tfloat oldT = 0.0;\n\tfloat delta = 0.;\n\tvec2 h = vec2(1.0, 1.0);\n\tbool hit = false;\n\tfor( int j=0; j < 70; j++ )\n\t{\n\t    vec3 p = rO + t*rD;\n        if (p.y > 90.0) break;\n\n\t\th = Map(p); // ...Get this position's height mapping.\n\n\t\t// Are we inside, and close enough to fudge a hit?...\n\t\tif( h.x < 0.05)\n\t\t{\n\t\t\thit = true;\n            break;\n\t\t}\n\t        \n\t\tdelta = h.x + (t*0.03);\n\t\toldT = t;\n\t\tt += delta;\n\t}\n    type = h.y;\n    resT = BinarySubdivision(rO, rD, t, oldT);\n\tfloat f = Sphere( rO, rD, vec4(camTar, 10.0));\n\t\n\tif (f > 0.0 && f < resT+4.5)\n\t{\n\t\thit = true;\n\t\ttype = 1.0;\n\t\tresT = f;\n\t\t\n\t\t\n\t}\n\treturn hit;\n}\n\n//--------------------------------------------------------------------------\nvec3 PostEffects(vec3 rgb, vec2 xy)\n{\n\t// Gamma first...\n\trgb = pow(rgb, vec3(0.45));\n\t\n\t// Then...\n\t#define CONTRAST 1.1\n\t#define SATURATION 1.3\n\t#define BRIGHTNESS 1.3\n\trgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb*BRIGHTNESS)), rgb*BRIGHTNESS, SATURATION), CONTRAST);\n\t// Vignette...\n\trgb *= .4+0.6*pow(40.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2 );\t\n\treturn rgb;\n}\n\n//--------------------------------------------------------------------------\nvoid main( void )\n{\n\t\n\tfloat gTime = (time*5.0+468.0)*.006;\n    vec2 xy = gl_FragCoord.xy / resolution.xy;\n\tvec2 uv = (-1.0 + 2.0 * xy) * vec2(resolution.x/resolution.y,1.0);\n\t\n\tif (xy.y < .13 || xy.y >= .87)\n\t{\n\t\t// Top and bottom cine-crop - what a waste! :)\n\t\tgl_FragColor=vec4(vec4(0.0));\n\t\treturn;\n\t}\n\n\tcameraPos = CameraPath(gTime + 0.0);\n    cameraPos.x-= 20.0;\n\tcamTar\t  = CameraPath(gTime + .06);\n\t\n\tvec2 diff = (camTar.xz - CameraPath(gTime + .13).xz);\n\tballRoll.x = -gTime * 72.0;\n\tballRoll.y = atan(diff.x, diff.y);\n\t\n\tcameraPos.y = Terrain(cameraPos.xz).x + 7.0;\n\tcamTar.y    = Terrain(camTar.xz).x+7.0;\n\tbounce = abs(sin(gTime*130.0))* 40.0 * max(abs(sin(gTime*15.0))-.85, 0.0);\n\tcamTar.y += bounce;\n\t\n\tfloat roll = .3*sin(gTime*3.0+.5);\n\tvec3 cw = normalize(vec3(camTar.x, cameraPos.y, camTar.z)-cameraPos);\n\tvec3 cp = vec3(sin(roll), cos(roll),0.0);\n\tvec3 cu = cross(cw,cp);\n\tvec3 cv = cross(cu,cw);\n\tvec3 dir = normalize(uv.x*cu + uv.y*cv + 1.3*cw);\n\tmat3 camMat = mat3(cu, cv, cw);\n\n\tvec3 col;\n\tfloat distance = 1e20;\n\tfloat type = 0.0;\n\tif( !Scene(cameraPos, dir, distance, type) )\n\t{\n\t\t// Missed scene, now just get the sky...\n\t\tcol = GetSky(dir, true);\n\t}\n\telse\n\t{\n\t\t// Get world coordinate of landscape...\n\t\tvec3 pos = cameraPos + distance * dir;\n\t\t// Get normal from sampling the high definition height map\n\t\tvec2 p = vec2(0.1, 0.0);\n\t\tvec3 nor  \t= vec3(0.0,\t\tTerrain(pos.xz).x, 0.0);\n\t\tvec3 v2\t\t= nor-vec3(p.x,\tTerrain(pos.xz+p).x, 0.0);\n\t\tvec3 v3\t\t= nor-vec3(0.0,\tTerrain(pos.xz-p.yx).x, -p.x);\n\t\tnor = cross(v2, v3);\n\t\tnor = normalize(nor);\n\n\t\t// Get the colour using all available data...\n\t\tcol = TerrainColour(pos, dir, nor, distance, type);\n\t}\n\t\n\t// bri is the brightness of sun at the centre of the camera direction.\n\tfloat bri = dot(cw, sunLight)*.75;\n\tif (bri > 0.0)\n\t{\n\t\tvec2 sunPos = vec2( dot( sunLight, cu ), dot( sunLight, cv ) );\n\t\tvec2 uvT = uv-sunPos;\n\t\tuvT = uvT*(length(uvT));\n\t\tbri = pow(bri, 6.0)*.8;\n\n\t\t// glare = the red shifted blob...\n\t\tfloat glare1 = max(dot(normalize(vec3(dir.x, dir.y+.3, dir.z)),sunLight),0.0)*1.4;\n\t\t// glare2 is the yellow ring...\n\t\tfloat glare2 = max(1.0-length(uvT+sunPos*.5)*4.0, 0.0);\n\t\tuvT = mix (uvT, uv, -2.3);\n\t\t// glare3 is a purple splodge...\n\t\tfloat glare3 = max(1.0-length(uvT+sunPos*5.0)*1.2, 0.0);\n\n\t\tcol += bri * vec3(1.0, .0, .0)  * pow(glare1, 12.5)*.05;\n\t\tcol += bri * vec3(1.0, 1.0, 0.2) * pow(glare2, 2.0)*2.5;\n\t\tcol += bri * sunColour * pow(glare3, 2.0)*3.0;\n\t}\n\tcol = PostEffects(col, xy);\t\n\t\n\tgl_FragColor=vec4(col,1.0);\n}\n\n//--------------------------------------------------------------------------\n\nvoid main2( void ) {\n\n\tvec2 position = ( gl_FragCoord.xy / resolution.xy ) + mouse / 4.0;\n\n\tfloat color = 0.0;\n\tcolor += sin( position.x * cos( time / 15.0 ) * 80.0 ) + cos( position.y * cos( time / 15.0 ) * 10.0 );\n\tcolor += sin( position.y * sin( time / 10.0 ) * 40.0 ) + cos( position.x * sin( time / 25.0 ) * 40.0 );\n\tcolor += sin( position.x * sin( time / 5.0 ) * 10.0 ) + sin( position.y * sin( time / 35.0 ) * 80.0 );\n\tcolor *= sin( time / 10.0 ) * 0.5;\n\n\tgl_FragColor = vec4( vec3( color, color * 0.5, sin( color + time / 3.0 ) * 0.75 ), 1.0 );\n\n}", "user": "23500f", "parent": null, "id": "34155.1"}