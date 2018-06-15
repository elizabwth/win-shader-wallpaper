import urllib.request
import json

if __name__ == '__main__':
    shader_list_file = open('shader.list')

    shader_list = []
    for line in shader_list_file:
        if line == '':
            continue
        if line.startswith('#'):
            continue

        item = line.split(' ')
        item_id, title = item[0], item[-1].rstrip()

        shader_list.append((item_id, title))

    for s in shader_list:
        shader_id = s[0]
        shader_title = s[1]

        fp = urllib.request.urlopen(f"http://glslsandbox.com/item/{shader_id}")
        mybytes = fp.read()
        mystr = mybytes.decode("utf8")
        fp.close()

        fn = f".\\shader\\glslsandbox\\{shader_title}.glsl"
        f = open(fn, "w")

        shader_json = json.loads(mystr)
        shader_json['id'] = shader_id

        f.write(json.dumps(shader_json))

        print("writing", fn)
        f.close()

    print(shader_list)

