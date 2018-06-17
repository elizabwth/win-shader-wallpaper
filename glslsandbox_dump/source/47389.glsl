{"code": "/* - ~ iridule ~ */\n\n#ifdef GL_ES\nprecision mediump float;\n#endif\n#extension GL_OES_standard_derivatives : enable\n\nuniform float time;\nuniform vec2 resolution;\n\nvec2 iResolution;\nfloat iTime;\n\n#define repeat(v) mod(p + 1., 2.) -1.\nvoid mainImage(out vec4 O, in vec2 I) {\n    \tvec2 R = iResolution.xy;\n\tvec2 uv = (2. * I - R) / R.y;\t\n\tvec3 o = vec3(-1., 0., iTime), d  = vec3(uv, 1.), p;\n\tfloat t = 0.;\n\tfor (int i = 0; i < 32; i++) {\n\t\tp = o + d * t;\n\t\tp = repeat(p);\n\t\tt += (0.5 * length(p) - .3);\n\t}\n\tfloat l = .8 * dot(normalize(o - p), d);\n\tO = vec4(l  * vec3(1. / t), 1.);\n}\n\t\nvoid main(void) {\n\tiResolution = resolution;\n\tiTime = time;\n\tmainImage(gl_FragColor, gl_FragCoord.xy);\n}\n", "user": "537abd1", "parent": null, "id": 47389}