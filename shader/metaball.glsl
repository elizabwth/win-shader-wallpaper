// https://www.vertexshaderart.com/art/ZAHaRXC8kiQBzSkbb

#version 330 core
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

uniform float vertexCount;
uniform sampler2D volume;
uniform sampler2D sound;
uniform sampler2D floatSound;
uniform sampler2D touch;
uniform vec2 soundRes;

layout(location = 0)in vec3 vert;
out vec4 v_color;

#define PI05 1.570796326795
#define PI   3.1415926535898

#define kNumVertX   15.0
#define kNumVertY   15.0
//#define kNumVertZ
#define kScale      0.2
#define kTranslate  vec3(-1.5)

vec3 hash3(vec3 v) {
  return fract(sin(v) * vec3(43758.5453123, 12345.6789012,76543.2109876));
}

vec3 rotX(vec3 p, float rad) {
  vec2 sc = sin(vec2(rad, rad + PI05));
  vec3 rp = p;
  rp.y = p.y * sc.y + p.z * -sc.x;
  rp.z = p.y * sc.x + p.z *  sc.y;
  return rp;
}

vec3 rotY(vec3 p, float rad) {
  vec2 sc = sin(vec2(rad, rad + PI05));
  vec3 rp = p;
  rp.x =  p.x *  sc.y + p.z *  sc.x;
  rp.z =  p.x * -sc.x + p.z *  sc.y;
  return rp;
}

vec3 rotZ(vec3 p, float rad) {
  vec2 sc = sin(vec2(rad, rad + PI05));
  vec3 rp = p;
  rp.x =  p.x *  sc.x + p.y * sc.y;
  rp.y =  p.x * -sc.y + p.y * sc.x;
  return rp;
}

vec4 perspective(vec3 p, float fov, float near, float far) {
  vec4 pp = vec4(p, -p.z);
  pp.xy *= vec2(resolution.y / resolution.x, 1.0) / tan(radians(fov * 0.5));
  pp.z = (-p.z * (far + near) - 2.0 * far * near) / (far - near);
  return pp;
}

mat4 lookat(vec3 eye, vec3 look, vec3 up) {
  vec3 z = normalize(eye - look);
  vec3 x = normalize(cross(up, z));
  vec3 y = cross(z, x);
  return mat4(x.x, y.x, z.x, 0.0, x.y, y.y, z.y, 0.0, x.z, y.z, z.z, 0.0, 0.0, 0.0, 0.0, 1.0) * 
    mat4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, -eye.x, -eye.y, -eye.z, 1.0);
}

vec3 voxelPosToWorld(vec3 vxlp) {
    return vxlp * kScale + kTranslate;
}

float blobSphere(vec3 p, float r) {
    return 1.0 / (1.0 + pow(length(p / r), 2.0));
}

float scene(vec3 p) {
    const float kThreshould = 0.5;
    float d = 0.0;
    d += blobSphere(p + sin(time * vec3(1.5, 2.1, 0.5)) * vec3(0.5, 0.6, 0.3), 0.4);
    d += blobSphere(p + sin(time * vec3(2.3, 1.2, 1.7)) * vec3(0.6, 0.5, 0.8), 0.2);
    d += blobSphere(p + sin(time * vec3(0.3, 1.2, 2.7)) * vec3(0.5, 0.4, 0.5), 0.3);
    //d += 1.0 / (1.0 + pow(length(p * 2.0), 2.0));
    return kThreshould - d;
}

vec3 sceneNormal(vec3 p) {
    vec3 EPS = vec3(0.01, 0.0, 0.0);
    vec3 n;
    n.x = scene(p + EPS.xyz) - scene(p - EPS.xyz);
    n.y = scene(p + EPS.zxy) - scene(p - EPS.zxy);
    n.z = scene(p + EPS.yzx) - scene(p - EPS.yzx);
    return normalize(n);
}

vec3 smoothVertex(vec3 ip) {
    vec3 p = ip;
    vec3 n = sceneNormal(p);
    for(int i = 0; i < 8; i++) {
        float d = scene(p);
        p -= n * d;
        if(abs(d) < 0.01) { break; }
    }
    return p;
}

vec4 shading(vec3 p, vec3 n) {
    vec3 kDc = vec3(0.6, 0.05, 0.15);
    vec3 kSp = vec3(1.0, 1.0, 1.0) * 0.2;
    vec3 kFc = vec3(0.3,0.1,0.15);
    vec3 L = normalize(vec3(1.0, 1.0, 1.0));
    float d = dot(L, n);
    float s = 0.0;
    if(d > 0.0) {
        vec3 h = (normalize(-p) + L) * 0.5;
        s = pow(max(0.0, dot(h, n)), 4.0);
    }
    float kR0 = 0.02;
    float F =  kR0 + (1.0 - kR0) * pow(1.0 - max(0.0, dot(normalize(-p), n)), 5.0);
    
    return vec4((max(0.0, d) * 0.6 + 0.2) * kDc + s * kSp + F * kFc, 1.0);
}

void main() {
    // vertex index in quad face (2 triangles: 0-5)
    float faceVertId = mod(gl_VertexID, 6.0);
    // face index
    float faceId = floor(gl_VertexID / 6.0);
    // fece index in corner
    float cornerFaceId = mod(faceId, 3.0);
    // edge index in corner
    float cornerEdgeId = mod(faceId, 3.0);
    // corner index (1 corner = 3 faces = 3 * 6 verts)
    float cornerId = floor(gl_VertexID / 18.0);
    // corner position
    vec3 cornerPos;
    cornerPos.x = mod(cornerId, kNumVertX);
    cornerPos.y = mod(floor(cornerId / kNumVertX), kNumVertY);
    cornerPos.z = mod(floor(cornerId / (kNumVertX * kNumVertY)), kNumVertY);
    
    vec3 faceNormal;
    vec3 faceTangent;
    vec3 faceCotangent;
    vec3 faceColor;
    if(cornerEdgeId == 0.0) {
        faceNormal = vec3(1.0, 0.0, 0.0);
        faceTangent = vec3(0.0, 0.0, -1.0);
        faceCotangent = vec3(0.0, 1.0, 0.0);
    } else if(cornerEdgeId == 1.0) {
        faceNormal = vec3(0.0, 1.0, 0.0);
        faceTangent = vec3(1.0, 0.0, 0.0);
        faceCotangent = vec3(0.0, 0.0, -1.0);
    } else {
        faceNormal = vec3(0.0, 0.0, 1.0);
        faceTangent = vec3(1.0, 0.0, 0.0);
        faceCotangent = vec3(0.0, 1.0, 0.0);
    }
    vec3 anotherPos = cornerPos + faceNormal;
    
    // sampling points
    vec3 p0 = voxelPosToWorld(cornerPos);
    vec3 p1 = voxelPosToWorld(anotherPos);
    
    // field value
    float d0 = scene(p0);
    float d1 = scene(p1);
    
    vec3 p;
    vec3 vertNorm;
    
    if(d0 * d1 > 0.0) {
        // no face
        p = p0;
        vertNorm = vec3(1.0, 1.0, 1.0);
    } else {
        // have a face
        if(d1 < d0) {
            // 0->1 is standard normal.
            // otherwise flip triangle
            if(faceVertId == 0.0) {
                faceVertId = 2.0;
            } else if(faceVertId == 2.0) {
                faceVertId = 0.0;
            } else if(faceVertId == 3.0) {
                faceVertId = 5.0;
            } else if(faceVertId == 5.0) {
                faceVertId = 3.0;
            }
            faceNormal *= -1.0;
        }
        
        /*
        face
        2 4-5
        |\ \|
        0-1 3
        */
        float kFaceSize = mix(0.45, 0.5, clamp(cos(time * 1.5) * 4.0 + 0.5, 0.0, 1.0));
        vec3 edgeMidPos = (cornerPos + anotherPos) * 0.5;
        vec3 faceVertPos;
        if(faceVertId == 0.0) {
            faceVertPos = edgeMidPos + faceTangent * -kFaceSize + faceCotangent * -kFaceSize;
        } else if(faceVertId == 1.0) {
            faceVertPos = edgeMidPos + faceTangent *  kFaceSize + faceCotangent * -kFaceSize;
        } else if(faceVertId == 2.0) {
            faceVertPos = edgeMidPos + faceTangent * -kFaceSize + faceCotangent *  kFaceSize;
        } else if(faceVertId == 3.0) {
            faceVertPos = edgeMidPos + faceTangent *  kFaceSize + faceCotangent * -kFaceSize;
        } else if(faceVertId == 4.0) {
            faceVertPos = edgeMidPos + faceTangent * -kFaceSize + faceCotangent *  kFaceSize;
        } else if(faceVertId == 5.0) {
            faceVertPos = edgeMidPos + faceTangent *  0.5 + faceCotangent *  0.5;
        }
        p = voxelPosToWorld(faceVertPos);
        
        // smoothing
        vec3 sp = smoothVertex(p);
        vertNorm = sceneNormal(p);
        
        float vmix = clamp(sin(time * 0.35) * 2.0 + 0.5, 0.0, 1.0);
        p = mix(p, sp, vmix);
        vertNorm = mix(faceNormal, vertNorm, vmix);
    }
    
    vec3 eye = rotX(rotY(vec3(0.0, 0.0, 3.5), -mouse.x * 2.0), mouse.y);
    //vec3 eye = vec3(0.0, 0.0, 3.0);
    mat4 viewMat = lookat(eye, vec3(0.0), vec3(0.0, 1.0, 0.0));
    vec3 viewPos = (viewMat * vec4(p, 1.0)).xyz;
    vec3 viewNorm = normalize((viewMat * vec4(vertNorm, 0.0)).xyz);
    
    gl_Position = perspective(viewPos, 40.0, 0.1, 10.0);
    gl_PointSize = 2.0;
    //v_color = vec4(abs(faceNormal), 1.0);
    //v_color = vec4(vertNorm * 0.5 + 0.5, 1.0);
    //v_color = vec4(viewNorm * 0.5 + 0.5, 1.0);
    v_color = shading(viewPos, viewNorm);
}
