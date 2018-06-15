{"code": "////based on  https://www.shadertoy.com/view/Ml2GWy\n\n// Created by inigo quilez - iq/2015\n// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.\n\n#ifdef GL_ES\nprecision mediump float;\n#endif\n\nuniform float time;\nuniform vec2 mouse;\nuniform vec2 resolution;\n\nvoid main( void ) {\n\n\tvec2 uv = 256.0 * ( gl_FragCoord.xy / resolution.x ) + vec2(time) ;\n\n\t\n\tvec3 col = vec3(0.0);\n\t\n        for( int i=0; i<4; i++ )\n\t{\n\t\tuv/=2.0;\n\t\t\n\t\tvec2 a = floor(uv);        \n\t\tvec2 b = fract(uv);\n \n\t\tvec4 w = fract((sin(a.x*7.0+31.0*a.y + 0.01*time)+vec4(0.035,0.01,0.0,0.7))*13.545317); // randoms       \n         \n\t\tcol += smoothstep(0.45,0.55,w.w) *               // intensity\n\t\t\tvec3(sqrt( 16.0*b.x*b.y*(1.0-b.x)*(1.0-b.y))); // pattern\t\n\n\t\t//col = pow( 0.5 * col, vec3(1.0,1.0,0.7) );    // contrast and color shape\n\t\t\n\t\t//col.r = pow( 0.8 * col.r ,  .9 );\n\t\t//col.g = pow( 1.0 * col.g , 1.0 );\n\t\t//col.b = pow( 1.0 * col.b , 0.7 );\n\t\n\t\tcol = pow( vec3(0.82,1.0,.91) * col, vec3(0.8,1.0,.7) );    // contrast and color shape\n\t}\n\tcol += vec3(0.1,0.2,0.15);\n\tgl_FragColor = vec4( col , 1.0 );\n}", "user": "c0584c2", "parent": null, "id": "27993.1"}