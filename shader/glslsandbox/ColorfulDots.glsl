{"code": "#ifdef GL_ES\nprecision mediump float;\n#endif\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\n\nvoid main( void ) {\n\tfloat N = 30.;\n\tfloat invN = 1./N;\n\tvec2 position = ( gl_FragCoord.xy / resolution.xy ) + mod(time,invN) / 3.0;\n\tvec2 cell = vec2(ivec2(invN*gl_FragCoord.xy));\n\tvec2 center = N*vec2(cell)+vec2(0.5*N,0.5*N);\n\tfloat d = distance(gl_FragCoord.xy, center);\n\tfloat c = 1.-smoothstep(0.4 * N, 0.45*N, d*.9);\n\tvec4 bg = vec4(.3,.1,.7,1.);\n\tfloat a0 = 0.5+0.5*sin(0.9*cell.x +time)*sin(cell.y + 5.*cos(0.4*time));\n\tfloat a1 = 0.5+0.5*sin(0.1*cell.y+10.*sin(cell.x)*time*0.2);\n\t\n\t\t\n\tfloat y = 0.5*(a0+a1);\n\tvec4 top_bw = vec4(y);\n\tvec4 top_c = vec4(a0,a1,0.,1.);\n\tfloat d2 = distance(resolution.xy*inversesqrt(-time), center);\n\tfloat s = smoothstep(-0.5*N, 3.*N,d2)-smoothstep(3.*N,6.*N,d2);\n\ts = step(8.*N,d2)-step(9.*N,d2) + 1. - step(0.5*N,d2);\n\tvec4 top = mix(0.5*top_bw, top_c, s*s);\n\tgl_FragColor = mix(bg,top,c);\n\tgl_FragColor *= (top_c,bg,s+c)/mod(y,time)-3.0;\n}", "user": "51af143", "parent": "/e#21297.3", "id": "26933.0"}