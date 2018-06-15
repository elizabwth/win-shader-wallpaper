{"code": "#ifdef GL_ES\nprecision mediump float;\n#endif\n\nuniform float time;\nuniform vec2 resolution;\n\nvec3 color( const float a ) \n{\n\tfloat r = -1. + min( mod( a     , 6. ), 6. - mod( a     , 6. ) );\n\tfloat g = -1. + min( mod( a + 2., 6. ), 6. - mod( a + 2., 6. ) );\n\tfloat b = -1. + min( mod( a + 4., 6. ), 6. - mod( a + 4., 6. ) );\n\t\n\tr = clamp( r, 0., 1. );\n\tg = clamp( g, 0., 1. );\n\tb = clamp( b, 0., 1. );\n\t\n\treturn vec3( r,g,b );\n}\n\nvec2 toPolar( vec2 uv )\n{\n\tfloat a = atan( uv.y, uv.x );\n\tfloat l = length( uv );\n\t\n\tuv.x = a / 3.1415926;\n\tuv.y = l;\n\t\n\treturn uv;\n}\n\nvoid main( void ) {\n\tvec2 p = ( gl_FragCoord.xy / resolution.xy ) * 2. - 1.;\n\tp.x *= resolution.x/resolution.y;\n\tfloat f = length(p);\n\t\n\tp = toPolar(p);\n\tp.x += sin(time - f) * clamp( -cos(time*.1) * 4. + 3., 0., 1.);\n\t\n\tgl_FragColor = vec4( color(p.x*3.), 1.) * (smoothstep( .01,.0,f -1.));\n\tgl_FragColor = mix( gl_FragColor, vec4(1.), 1.-f);\n}", "user": "aefc2ec", "parent": null, "id": "27823.1"}