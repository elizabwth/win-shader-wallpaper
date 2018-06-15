{"code": "//Procedural Cubemaps by nimitz (twitter: @stormoid)\n\n/*\n\tFollow up on my \"sphere mappings\" shader(https://www.shadertoy.com/view/4sjXW1).\n\tUsing said mapping to draw a procedural\t4-way symmetrical texture.\n\n\tAs far as I know, wallpaper group p4mm needs to be used for this to work\n\twithout symmetry issues (http://en.wikipedia.org/wiki/Wallpaper_group#Group_p4mm)\n\t(Otherwise you need to map the faces independently)\n\n\tThe procedural symmetric texture is from my \"Colorful tessellation\" shader\n\t(https://www.shadertoy.com/view/lslXDn)\n*/\n\n#ifdef GL_ES\nprecision mediump float;\n#endif\n\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\n\n#define POST\n\nfloat hash2(in vec2 n){ return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453); }\n\nmat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,-s,s,c);}\n\nvec2 field(in vec2 x)\n{\n    vec2 n = floor(x);\n\tvec2 f = fract(x);\n\tvec2 m = vec2(5.,1.);\n\tfor(int j=0; j<=1; j++)\n\tfor(int i=0; i<=1; i++)\n    {\n\t\tvec2 g = vec2( float(i),float(j) );\n\t\tvec2 r = g - f;\n        float d = length(r)*(sin(time*0.12)*0.5+1.5); //any metric can be used\n        d = sin(d*5.+abs(fract(time*0.1)-0.5)*1.8+0.2);\n\t\tm.x *= d;\n\t\tm.y += d*1.2;\n    }\n\treturn abs(m);\n}\n\nvec3 tex(in vec2 p, in float ofst)\n{    \n    vec2 rz = field(p*ofst*0.5);\n\tvec3 col = sin(vec3(2.,1.,.1)*rz.y*.2+3.+ofst*2.)+.9*(rz.x+1.);\n\tcol = col*col*.5;\n    col *= sin(length(p)*9.+time*5.)*0.35+0.65;\n\treturn col;\n}\n\nvec3 cubem(in vec3 p, in float ofst)\n{\n    p = abs(p);\n    if (p.x > p.y && p.x > p.z) return tex( vec2(p.z,p.y)/p.x,ofst );\n    else if (p.y > p.x && p.y > p.z) return tex( vec2(p.z,p.x)/p.y,ofst );\n    else return tex( vec2(p.y,p.x)/p.z,ofst );\n}\n\nfloat sphere(in vec3 ro, in vec3 rd)\n{\n    float b = dot(ro, rd);\n    float c = dot(ro, ro) - 1.;\n    float h = b*b - c;\n    if(h <0.0) return -1.;\n    else return -b - sqrt(h);\n}\n\nvoid main()\n{\t\n\tvec2 p = gl_FragCoord.xy / resolution.xy-0.5;\n    vec2 bp = p+0.5;\n\tp.x*=resolution.x/resolution.y;\n\tvec2 um = mouse.xy / resolution.xy-.5;\n\tum.x *= resolution.x/resolution.y;\n\t\n    //camera\n\tvec3 ro = vec3(0.,0.,4.);\n    vec3 rd = normalize(vec3(p,-1.6));\n    mat2 mx = mm2(time*0.25+um.x*5.);\n    mat2 my = mm2(time*0.27+um.y*5.); \n    ro.xz *= mx;rd.xz *= mx;\n    ro.xy *= my;rd.xy *= my;\n    \n    float sel = mod(floor(time*0.3),4.);\n    \n    float t = sphere(ro,rd);\n    vec3 col = vec3(0);\n    float bg = clamp(dot(-rd,vec3(0.577))*0.3+.6,0.,1.);\n    col = cubem(rd,3.)*bg*.4;\n    \n    if (t > 0.)\n    {\n    \tvec3 pos = ro+rd*t;\n        vec3 rf = reflect(rd,pos);\n        float dif = clamp(dot(rd,vec3(0.577))*0.3+.6,0.,1.);\n        col = (cubem(rf,3.)*0.015+cubem(pos,1.)*0.7)*dif;\n    }\n    \n    #ifdef POST\n    //vign from iq (very nice!)\n\tcol *= pow(16.0*bp.x*bp.y*(1.0-bp.x)*(1.0-bp.y),.45);\n    col *= sin(bp.y*450.*resolution.y+time*0.1)*0.02+1.;\n    #endif\n    \n\tgl_FragColor = vec4(pow(col,vec3(0.7)), 1.0);\n}", "user": "52ded71", "parent": null, "id": "40851.0"}