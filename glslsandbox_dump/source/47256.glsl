{"code": "/*\n * Original shader from: https://www.shadertoy.com/view/MdcfWH\n */\n\n#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// glslsandbox uniforms\nuniform float time;\nuniform vec2 resolution;\n\n// shadertoy globals\nfloat iTime;\nvec3  iResolution;\n\n// --------[ Original ShaderToy begins here ]---------- //\n////////////////////////////////////////////////////////////////////////////////\n//\n// Copyright 2018 Mirco M\u00fcller\n//\n// Author(s):\n//   Mirco \"MacSlow\" M\u00fcller <macslow@gmail.com>\n//\n// This program is free software: you can redistribute it and/or modify it\n// under the terms of the GNU General Public License version 3, as published\n// by the Free Software Foundation.\n//\n// This program is distributed in the hope that it will be useful, but\n// WITHOUT ANY WARRANTY; without even the implied warranties of\n// MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR\n// PURPOSE.  See the GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License along\n// with this program.  If not, see <http://www.gnu.org/licenses/>.\n//\n////////////////////////////////////////////////////////////////////////////////\n\nconst bool VISUALIZE_DEPTH = false;\nconst int MAX_STEPS = 128;\nconst float LARGE_STEP = .5;   // these should be 1.6 and 1.0 usually, but deforming\nconst float SMALL_STEP = .125;  // and bending some objects require smaller steps :/\n\nfloat hash (float f)\n{\n\treturn fract (sin (f) * 45734.5453);\n}\n\nfloat noise3d (vec3 p)\n{\n    vec3 u = floor (p);\n    vec3 v = fract (p);\n    \n    v = v * v * (3. - 2. * v);\n\n    float n = u.x + u.y * 57. + u.z * 113.;\n    float a = hash (n);\n    float b = hash (n + 1.);\n    float c = hash (n + 57.);\n    float d = hash (n + 58.);\n\n    float e = hash (n + 113.);\n    float f = hash (n + 114.);\n    float g = hash (n + 170.);\n    float h = hash (n + 171.);\n\n    float result = mix (mix (mix (a, b, v.x),\n                             mix (c, d, v.x),\n                             v.y),\n                        mix (mix (e, f, v.x),\n                             mix (g, h, v.x),\n                             v.y),\n                        v.z);\n\n    return result;\n}\n\nmat3 rotY (in float angle)\n{\n    float rad = radians (angle);\n    float c = cos (rad);\n    float s = sin (rad);\n\n    mat3 mat = mat3 (vec3 ( c, .0, -s),\n                     vec3 (.0, 1,  .0),\n                     vec3 ( s, .0,  c));\n\n    return mat;\n}\n\nmat3 rotZ (in float angle)\n{\n    float rad = radians (angle);\n    float c = cos (rad);\n    float s = sin (rad);\n\n    mat3 mat = mat3 (vec3 (  c,  -s, 0.0),\n                     vec3 (  s,   c, 0.0),\n                     vec3 (0.0, 0.0, 1.0));\n\n    return mat;\n}\n\nfloat fbm (vec3 p)\n{\n\tmat3 m1 = mat3 (rotZ (23.4));\n\tmat3 m2 = mat3 (rotZ (45.5));\n\tmat3 m3 = mat3 (rotZ (77.8));\n\n    float result = .0;\n    result = 0.5 * noise3d (p);\n    p *= m1 * 2.02;\n    result += 0.25 * noise3d (p);\n    p *= m2 * 2.03;\n    result += 0.125 * noise3d (p);\n    p *= m3 * 2.04;\n    result += 0.0625 * noise3d (p);\n    result /= 0.9375;\n\n    return result;\n}\n\nfloat sphere (vec3 p, float size)\n{\n\treturn length (p) - size;\n}\n\nfloat plane (vec3 p)\n{\n    return p.y + .25;\n}\n\nfloat opBend (inout vec3 p, float deg)\n{\n    float rad = radians (deg);\n    float c = cos (rad * p.y);\n    float s = sin (rad * p.y);\n    mat2  m = mat2 (c, -s, s, c);\n    p = vec3 (m * p.xy, p.z);\n    return .0;\n}\n\nfloat displace (vec3 p)\n{\n    float result = 1.;\n    float factor = 2. + (.5 + .5 * cos (iTime));\n    result =  sin (factor * p.x) * cos (factor * p.y) * sin (factor * p.z);\n    return result;\n}\n\nvec2 map (vec3 p)\n{\n    float dt = .0;\n    float dp = .0;\n\tvec3 w = vec3 (.0);\n\tvec2 d1 = vec2 (.0);\n\tmat3 m = rotY (20. * iTime) * rotZ (-20. * iTime);\n\n    // floor\n    vec2 d2 = vec2 (plane (p), 2.);\n\n    // blue warping gyroid\n    w = -m * (p + vec3 (.0, -1.5, .0));\n    opBend (w, 7. * cos (iTime));\n    d1.y = 3.;\n    float thickness = .075;\n    float cubeSize = 6.;\n    float surfaceSide = dot (sin (w), cos (w.yzx));\n    d1.x = abs (surfaceSide) - thickness;\n    vec3 a = abs (w);\n    d1.x = max (d1.x, max(a.x, max (a.y, a.z)) - cubeSize);\n\n    // only the nearest survives :)\n    if (d2.x < d1.x) {\n        d1 = d2;\n    }\n\n\treturn d1;\n}\n\nvec3 normal (vec3 p)\n{\n    vec2 e = vec2 (.001, .0);\n    return normalize (vec3 (map (p + e.xyy).x,\n                            map (p + e.yxy).x,\n                            map (p + e.yyx).x) - map (p).x);\n}\n\nvec3 march (vec3 ro, vec3 rd)\n{\n    float pixelSize = 1. / iResolution.x;\n    bool forceHit = true;\n    float infinity = 10000000.0;\n    float t_min = .0000001;\n    float t_max = 1000.0;\n    float t = t_min;\n    vec3 candidate = vec3 (t_min, .0, .0);\n    vec3 candidate_error = vec3 (infinity, .0, .0);\n    float w = LARGE_STEP;\n    float lastd = .0;\n    float stepSize = .0;\n    float sign = map (ro).x < .0 ? -1. : 1.;\n\n    for (int i = 0; i < MAX_STEPS; i++)\n\t{\n        float signedd = sign * map (ro + rd * t).x;\n        float d = abs (signedd);\n        bool fail = w > 1. && (d + lastd) < stepSize;\n\n        if (fail) {\n            stepSize -= w * stepSize;\n            w = SMALL_STEP;\n        } else {\n            stepSize = signedd * w;\n        }\n\n\t\tlastd = d;\n\n        float error = d / t;\n        if (!fail && error < candidate_error.x) {\n            candidate_error.x = error;\n            candidate.x = t;\n        }\n\n        if (!fail && error < pixelSize || t > t_max) {\n        \tbreak;\n\t\t}\n\n        candidate_error.y = map (ro + rd * t).y;\n        candidate.y = candidate_error.y;\n\n        candidate_error.z = float (i);\n        candidate.z = candidate_error.z;\n\n        t += stepSize;\n \n\t}\n\n    if ((t > t_max || candidate_error.x > pixelSize) && !forceHit) {\n        return vec3 (infinity, .0, .0);\n    }\n\n\treturn candidate;\n}\n\nfloat shadow (vec3 ro, vec3 rd)\n{\n    float result = 1.;\n    float t = .1;\n    for (int i = 0; i < 64; i++) {\n        float h = map (ro + t * rd).x;\n        if (h < 0.00001) return .0;\n        result = min (result, 4. * h/t);\n        t += h*.5;\n    }\n\n    return result;\n}\n\nvec3 floorMaterial (vec3 pos)\n{\n    vec3 col = vec3 (.6, .5, .3);\n    float f = fbm (pos * vec3 (6., .0, .5));\n    col = mix (col, vec3 (.3, .2, .1), f);\n    f = smoothstep (.6, 1., fbm (48. * pos));\n    col = mix (col, vec3 (.2, .2, .15), f);\n\n    return col;\n}\n\nvec3 thingMaterial (vec3 pos)\n{\n\treturn vec3 (sin(time), .4/sin(time), .3/sin(time));\n}\n\nvoid mainImage (out vec4 fragColor, in vec2 fragCoord)\n{\n    vec2 aspect = vec2 (iResolution.x/ iResolution.y, 1.);\n    vec2 uv = fragCoord.xy / iResolution.xy;\n    vec2 p = vec2 (-1. + 2. * uv) * aspect;\n\n    vec3 ro = 9. * vec3 (cos (.2 * iTime), 1.25, sin (.2 * iTime));\n    vec3 ww = normalize (vec3 (.0, 1., .0) - ro);\n    vec3 uu = normalize (cross (vec3 (.0, 1., .0), ww));\n    vec3 vv = normalize (cross (ww, uu));\n    vec3 rd = normalize (p.x * uu + p.y * vv + 1.5 * ww);\n\n    // \"look\" into the world\n    vec3 t = march (ro, rd);\n\n    // base infinity-color (when nothing was \"seen\")\n    vec3 col = vec3 (.8);\n\n    // otherwise do all the lighting- and material-calculations\n    if (t.y > .5) {\n        vec3 pos = ro + t.x * rd;\n        vec3 nor = normal (pos);\n        vec3 lig = normalize (vec3 (1., .8, .6));\n        vec3 blig = normalize (vec3 (-lig.x, lig.y, -lig.z));\n        vec3 ref = normalize (reflect (rd, nor));\n\n        float con = 1.;\n        float amb = .5 + .5 * nor.y;\n        float diff = max (dot (nor, lig), .0);\n        float bac = max (.2 + .8 * dot (nor, blig), .0);\n        float sha = shadow (pos, lig);\n        float spe = pow (clamp (dot (ref, lig), .0, 1.), 8.);\n        float rim = pow (1. + dot (nor, rd), 2.5);\n\n        col  = con  * vec3 (.1, .15, .2);\n        col += amb  * vec3 (.1, .15, .2);\n        col += diff * vec3 (1., .97, .85) * sha;\n        col += spe * vec3 (.9, .9, .9);\n        col += bac;\n\n        // either display ray-marching depth or materials\n        if (VISUALIZE_DEPTH) {\n\t        col *= vec3 (1. - t.z / float (MAX_STEPS));\n        } else {\n            if (t.y == 2.) {\n                col *= floorMaterial (pos);\n            } else if (t.y == 3.) {\n                col *= thingMaterial (pos);\n            }\n        }\n\n        col += .6 * rim * amb;\n        col += .6 * spe * sha * amb;\n\n        // color-correction\n        col *= vec3 (.95, .9, .85);\n        col = col / (.75 + col);\n        col = .2 * col + .8 * sqrt (col);\n    }\n\n    // put slight vignette over image\n    col *= .2 + .8 * pow (16. * uv.x * uv.y * (1. - uv.x) * (1. - uv.y), .2);\n\n    // after all this work, put the final color to screen\n    fragColor = vec4(col, 1.);\n}\n// --------[ Original ShaderToy ends here ]---------- //\n\nvoid main(void)\n{\n    iTime = time;\n    iResolution = vec3(resolution, 0.0);\n\n    mainImage(gl_FragColor, gl_FragCoord.xy);\n}", "user": "d4731ad", "parent": "/e#47231.0", "id": 47256}