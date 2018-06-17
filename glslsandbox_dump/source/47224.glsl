{"code": "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#extension GL_OES_standard_derivatives : enable\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\n\nvoid main( void ) {\n\n\tvec2 pos=(gl_FragCoord.xy/resolution)*2.0-1.0 ;\n\tpos.x*=resolution.x/resolution.y ;\n\t\n\t\n\tvec3 color=vec3(0.07) ;\n\t\n\tpos*=1.0/sin(time) ;\n\t\n\tcolor=vec3(0.009/pow(distance(pos, vec2(0.0)),4.0))*pow(pos.x,3.0)*4.0 ;\n\t\n\t\n\t\n\t\n\t\n\tgl_FragColor=vec4(color,1.0) ;\n}", "user": "f7bf52c", "parent": null, "id": 47224}