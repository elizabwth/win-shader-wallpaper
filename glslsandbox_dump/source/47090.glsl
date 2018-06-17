{"code": "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#extension GL_OES_standard_derivatives : enable\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\n\nvoid main( void ) {\n\n\tvec2 center = ( gl_FragCoord.xy / resolution.xy ) - 0.5;\n\tfloat distanceFromCenter = length(center);\n\tfloat radius = 0.2;\n\t\n\t//uncomment me to modulate the radius based on the current time\n\tradius *= sin(time) + 1.0;\n\t\n\tfloat hardEdgeThreshold = step(radius, distanceFromCenter);\t\n\tgl_FragColor = vec4(vec3(hardEdgeThreshold), 1.0 );\n\n}", "user": "2a1199e", "parent": "/e#44982.0", "id": 47090}