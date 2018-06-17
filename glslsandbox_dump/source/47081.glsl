{"code": "//fruityripple \n#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#extension GL_OES_standard_derivatives : enable\n\nuniform float time;\nuniform vec2 resolution;\nvoid main(void) {\n\n\tvec2 uv = ( gl_FragCoord.xy / resolution.xy );\n\tvec2 vx = ( gl_FragCoord.xy / uv);\n\n\tfloat f1=sin(sqrt(uv.x*uv.y))/sin(uv.y*sqrt(uv.x*vx.x));\n\tfloat f2=1.0*sin(time);\n\tfloat c1 = 3.0*f2 - (3.*length(2.*uv-sin(time)));\n\n\tgl_FragColor = vec4(pow(max(f1-sin(c1*f2),2.5),0.5-sin(time*5.)),pow(max(-c1,0.5),0.5),atan(sqrt(f1*sin(f1-c1))), 1.0 );\n}", "user": "d4731ad", "parent": null, "id": 47081}