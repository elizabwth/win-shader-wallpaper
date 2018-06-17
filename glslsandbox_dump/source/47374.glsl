{"code": "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#extension GL_OES_standard_derivatives : enable\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\nuniform sampler2D backbuffer;\n\nvec2 tex(vec2 uv)\n{\n\treturn texture2D(backbuffer, uv).xy - 0.5;\n}\n\nvoid main( void ) {\n\n\tvec2 pos = ( gl_FragCoord.xy / resolution.xy) - mouse;\n\tvec2 uv =  ( gl_FragCoord.xy / resolution.xy );\n\tvec2 prev = tex(uv);\n\tvec2 pixel = 1./resolution;\n\n\t// \u30e9\u30d7\u30e9\u30b7\u30a2\u30f3\u30d5\u30a3\u30eb\u30bf\u3067\u52a0\u901f\u5ea6\u3092\u8a08\u7b97\n\tfloat accel = (\n\t\ttex(uv + pixel * vec2(-1, -1)).x +\n\t\ttex(uv + pixel * vec2(1, -1)).x +\n\t\ttex(uv + pixel * vec2(-1, 1)).x +\n\t\ttex(uv + pixel * vec2(1, 1)).x +\n\t\ttex(uv + pixel * vec2(0, 1)).x * 2. +\n\t\ttex(uv + pixel * vec2(1, 0)).x * 2. +\n\t\ttex(uv + pixel * vec2(0, -1)).x * 2. +\n\t\ttex(uv + pixel * vec2(-1, 0)).x * 2. +\n\t\ttex(uv).x * 4.\n\t) / 16. - prev.x;\n\t\n\t// \u4f1d\u64ad\u901f\u5ea6\u3092\u639b\u3051\u308b\n\taccel *= 4.0;\n\n\t// \u73fe\u5728\u306e\u901f\u5ea6\u306b\u52a0\u901f\u5ea6\u3092\u8db3\u3057\u3001\u3055\u3089\u306b\u6e1b\u8870\u7387\u3092\u639b\u3051\u308b\n\tfloat velocity = (prev.y + accel) * 0.9;\n\n\t// \u9ad8\u3055\u3092\u66f4\u65b0\n\tfloat height = prev.x + velocity;\n\n\t// \u30de\u30a6\u30b9\u4f4d\u7f6e\u306b\u6ce2\u7d0b\u3092\u51fa\u3059\n\tif (fract(time) < 0.1) {\t\t\t\n\t\theight += (sin((length(pos) - time * 20.) * 3.) * .5 + .5) / length(pos * 300.);\n\t}\n\tgl_FragColor = vec4(height + 0.5, velocity + 0.5, 0, 1);\n\n}", "user": "f59ba62", "parent": "/e#37120.9", "id": 47374}