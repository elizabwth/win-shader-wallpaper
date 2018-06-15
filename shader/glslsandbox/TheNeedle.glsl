{"code": "/*\n * Original shader from: https://www.shadertoy.com/view/XsXGR4\n */\n\n#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// glslsandbox uniforms\nuniform float time;\nuniform vec2 resolution;\n\n// shadertoy globals\nfloat iTime;\nvec3  iResolution;\n\n// --------[ Original ShaderToy begins here ]---------- //\n// Copyright (c) 2012-2013 Andrew Baldwin (baldand)\n// License = Attribution-NonCommercial-ShareAlike (http://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US)\n// Logo from http://thndl.com/\n\nvoid mainImage( out vec4 fragColor, in vec2 fragCoord )\n{\n\tvec2 d=1./iResolution.xy;\n\tvec2 scale=vec2(iResolution.x/iResolution.y,1.)*2.1;\n\tvec2 c=(.5-fragCoord.xy*d)*scale;\n\t// d is used later for anti-aliasing\n\td*=scale;\n\tvec4 f;\n\t\n\t// Angle of the needle from top in radians\n\tfloat o=1.5*sin(3.*sin(iTime*.271)+.2*sin(iTime*7.1)+iTime*.1); \n\t\n\t// The needle (unfortunately not anti-aliased at top and bottom)\n\tvec2 b=vec2(c.x*cos(o)-c.y*sin(o), c.x*sin(o)+c.y*cos(o));\n\tfloat r,s,l,h,i,k,m,n;\n\tm=clamp(1.5-abs(b.y),0.2,1.5)+d.x*50.;\n\ti=step(-0.01,c.y);\n\th=step(-0.01,b.y);\n\tk=step(-0.99,b.y)*(1.-h)*(1.-smoothstep(0.027*m-d.x*2., 0.03*m,abs(b.x)));\n\t\n\t// The colour wheel\n\tl=length(c);\n\tr=1.0-smoothstep(1.-d.x*2.,1.,l);\n\ts=1.0-smoothstep(.5-d.x*2.,0.5,l);\n\tfloat t=atan(c.x/c.y);\n\tfloat u=(t+3.141*0.5)/3.141;\n\tvec4 ryg=vec4(0.69*clamp(mix(vec3(.0,2.,0.), vec3(2.,0.,0.),u),0.0,1.0),2.4-2.*l);\n\tvec4 tg=mix(vec4(ryg.rgb,0.),ryg,r);\n\tn=clamp(1.75*l-0.75,0.,1.);\n\tvec4 bg=mix(tg,vec4(0.,0.,0.,1.-n),i);\n\t\n\tfloat v=atan(c.x,c.y)-o;\n\tfloat vs=atan(c.x,c.y);\n\t\n\t// Base of the needle\n\tn=.9+.1*sin((20.*l+v)*5.);\n\tvec4 w=vec4(n,n,n,1.);\n\t\n\t// Shadow for the base of the needle\n\tvec4 e=mix(bg,w*vec4(vec3(abs(mod(vs+3.141*0.75, 2.*3.141)/3.141-1.)),1.),s);\n\t\n\t// Put it all together...\n\tf=mix(e,vec4(vec3(1.-(30.*abs((b.x/m+0.01)))),1.),k);\n\t\n\tfragColor=mix(vec4(0.2),f,f.a);\n}\n// --------[ Original ShaderToy ends here ]---------- //\n\nvoid main(void)\n{\n  iTime = time;\n  iResolution = vec3(resolution, 0.0);\n\n  mainImage(gl_FragColor, gl_FragCoord.xy);\n  gl_FragColor.a = 1.0;\n}", "user": "e405be3", "parent": null, "id": "46018.0"}