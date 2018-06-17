{"code": "// Conway's game of life\n\n#ifdef GL_ES\nprecision highp float;\n#endif\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\nuniform sampler2D backbuffer;\n\nvec4 live = vec4(0.5,1.0,0.7,1.);\nvec4 dead = vec4(0.,0.,0.,1.);\nvec4 blue = vec4(0.,0.,1.,1.);\n\nvoid main( void ) {\n\tvec2 position = ( gl_FragCoord.xy / resolution.xy );\n\tvec2 pixel = 1./resolution;\n\n\t/*if (length(position-mouse) < 0.01) {\n\t\tfloat rnd1 = mod(fract(sin(dot(position + time * 0.001, vec2(14.9898,78.233))) * 43758.5453), 1.0);\n\t\tif (rnd1 > 0.5) {\n\t\t\tgl_FragColor = live;\n\t\t} else {\n\t\t\tgl_FragColor = blue;\n\t\t}\n\t} else*/\n\t{\n\t\tfloat sum = 0.;\n\t\tsum += texture2D(backbuffer, position + pixel * vec2(-1., -1.)).g;\n\t\tsum += texture2D(backbuffer, position + pixel * vec2(-1., 0.)).g;\n\t\tsum += texture2D(backbuffer, position + pixel * vec2(-1., 1.)).g;\n\t\tsum += texture2D(backbuffer, position + pixel * vec2(1., -1.)).g;\n\t\tsum += texture2D(backbuffer, position + pixel * vec2(1., 0.)).g;\n\t\tsum += texture2D(backbuffer, position + pixel * vec2(1., 1.)).g;\n\t\tsum += texture2D(backbuffer, position + pixel * vec2(0., -1.)).g;\n\t\tsum += texture2D(backbuffer, position + pixel * vec2(0., 1.)).g;\n\t\tvec4 me = texture2D(backbuffer, position);\n\n\t\tif (me.g <= 0.1) {\n\t\t\tif ((sum >= 2.9) && (sum <= 3.1)) {\n\t\t\t\tgl_FragColor = live;\n\t\t\t} else if (me.b > 0.004) {\n\t\t\t\tgl_FragColor = vec4(0., 0., max(me.b - 0.004, 0.25), 0.);\n\t\t\t} else {\n\t\t\t\tgl_FragColor = dead;\n\t\t\t}\n\t\t} else {\n\t\t\tif ((sum >= 1.9) && (sum <= 3.1)) {\n\t\t\t\tgl_FragColor = live;\n\t\t\t} else {\n\t\t\t\tgl_FragColor = blue;\n\t\t\t}\n\t\t}\n\t}\n}", "user": "611809e", "parent": "/e#207.3", "id": 47026}