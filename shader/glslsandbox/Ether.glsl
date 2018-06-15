{"code": "/*\n * Original shader from: https://www.shadertoy.com/view/MsjSW3\n */\n\n#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// glslsandbox uniforms\nuniform float time;\nuniform vec2 resolution;\n\n// shadertoy globals\nfloat iTime;\nvec3  iResolution;\n\n// --------[ Original ShaderToy begins here ]---------- //\n//Ether by nimitz (twitter: @stormoid)\n\n#define t iTime\nmat2 m(float a){float c=cos(a), s=sin(a);return mat2(c,-s,s,c);}\nfloat map(vec3 p){\n    p.xz*= m(t*0.4);p.xy*= m(t*0.3);\n    vec3 q = p*2.+t;\n    return length(p+vec3(sin(t*0.7)))*log(length(p)+1.) + sin(q.x+sin(q.z+sin(q.y)))*0.5 - 1.;\n}\n\nvoid mainImage( out vec4 fragColor, in vec2 fragCoord ){\t\n\tvec2 p = fragCoord.xy/iResolution.y - vec2(.9,.5);\n    vec3 cl = vec3(0.);\n    float d = 2.5;\n    for(int i=0; i<=5; i++)\t{\n\t\tvec3 p = vec3(0,0,5.) + normalize(vec3(p, -1.))*d;\n        float rz = map(p);\n\t\tfloat f =  clamp((rz - map(p+.1))*0.5, -.1, 1. );\n        vec3 l = vec3(0.1,0.3,.4) + vec3(5., 2.5, 3.)*f;\n        cl = cl*l + (1.-smoothstep(0., 2.5, rz))*.7*l;\n\t\td += min(rz, 1.);\n\t}\n    fragColor = vec4(cl, 1.);\n}\n// --------[ Original ShaderToy ends here ]---------- //\n\nvoid main(void)\n{\n    iTime = time;\n    iResolution = vec3(resolution, 0.0);\n\n    mainImage(gl_FragColor, gl_FragCoord.xy);\n}", "user": "1072b8b", "parent": null, "id": "46667.0"}