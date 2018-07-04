import urllib.request
import json
import requests

def save_from_list():
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

        try:
            with open(f'.\\shader\\glslsandbox\\{shader_title}.glsl') as handler:
                s_id = shader_id.split('.')[0]
                print('writing', s_id, '.glsl')
                new_file = open(f'.\\shader\\glslsandbox_shaders\\{s_id}.glsl', "w")
                new_file.write(handler.read())
                new_file.close()
        except FileNotFoundError as e:
            print('failed to open', e)
        '''
        # download images
        img_id = shader_id.split('.')[0]
        img_data = requests.get(f"http://glslsandbox.com/thumbs/{img_id}.png").content
        with open(f'.\\shader\\thumbs\\{img_id}.png', 'wb') as handler:
            print("saving ...", img_id, )
            handler.write(img_data)
            print("done")
        '''
        '''
        # shader source json
        fp = urllib.request.urlopen(f"http://glslsandbox.com/item/{shader_id}")
        mybytes = fp.read()
        mystr = mybytes.decode("utf8")
        fp.close()


        # download shader source
        fn = f".\\shader\\glslsandbox\\{shader_title}.glsl"
        f = open(fn, "w")

        shader_json = json.loads(mystr)
        shader_json['id'] = shader_id

        f.write(json.dumps(shader_json))

        print("writing", fn)
        f.close()
        '''

    print(shader_list)

def _dump_from_glslsandbox():
    dump_dir = '.\\glslsandbox_dump\\'
    # last run end 47520-400
    start_id = 45000 - 50
    for i in range(50):
        shader_id = start_id - i

        # download images
        url = f"http://glslsandbox.com/thumbs/{shader_id}.png"
        print("saving...", url, )
        img_data = requests.get(url).content
        with open(f'{dump_dir}thumbs\\{shader_id}.png', 'wb') as handler:
            handler.write(img_data)
            print("done")

        # shader source json

        fp = urllib.request.urlopen(f"http://glslsandbox.com/item/{shader_id}")
        mybytes = fp.read()
        mystr = mybytes.decode("utf8")
        fp.close()

        # download shader source
        fn = f"{dump_dir}source\\{shader_id}.glsl"
        print("saving", fn, )
        with open(fn, 'w') as f:
            shader_json = json.loads(mystr)
            shader_json['id'] = shader_id

            f.write(json.dumps(shader_json))
            print("done")

def _rename_images():
    shader_list_file = open('shader.list')
    for line in shader_list_file:
        if line == '':
            continue
        if line.startswith('#'):
            continue

        item = line.split(' ')
        shader_id, shader_title = item[0], item[-1].rstrip()
        shader_id = shader_id.split('.')[0]

        with open(f'.\\shader\\dump\\thumbs\\{shader_id}.png', 'rb') as orig:
            with open(f'.\\shader\\dump\\thumbs\\{shader_title}.png', 'wb') as handler:
                handler.write(orig.read())
                print(f"renaming {shader_id} to {shader_title}.png", )
            print("done")


if __name__ == '__main__':
    # save_from_list(shader_list)
    #_dump_from_glslsandbox()
    _rename_images()
