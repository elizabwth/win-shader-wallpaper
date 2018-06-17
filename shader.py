import pyglet
import pyshaders
import win32gui
import win32api
from pyglet.gl import *

import json

vert_shader = '''
#version 330 core
uniform float time;
attribute vec3 position;

void main()
{
  gl_Position = vec4(position, 1);
}
'''


class ShaderWindow(pyglet.window.Window):
    def __init__(self, *args, **kwargs):
        super(ShaderWindow, self).__init__(*args, **kwargs)
        print("hwnd", self._hwnd)

        vert = './shader/vert.glsl'
        frag = './shader/frag/mouse2.glsl'
        self.shader_program = pyshaders.from_files_names(vert, frag)
        self.shader_program.use()

        tris = (-1, -1, -1, 1, 2, -1, 1, 1, -1, 1, 1, -1)
        self.polys = pyglet.graphics.vertex_list(6, ('v2f', tris))

        self.update_mouse_pos = False
        self.timescale = 1
        self.update_rate = 120

        self.backbuffer = None
        self.texture = pyglet.image.Texture.create(self.width, self.height, gl.GL_RGBA)
        gl.glEnable(gl.GL_DEPTH_TEST)
        gl.glEnable(gl.GL_BLEND)

        pyglet.clock.schedule_interval(self._update_shader_time,
                                       1 / self.update_rate)

    def on_draw(self):
        gl.glClearColor(0, 0, 0, 1)
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT)
        # vertex_list.draw(vert_mode)

        # window.clear()
        self.polys.draw(GL_TRIANGLES)

    def on_resize(self, width, height):
        self.copyFramebuffer(self.texture, width, height)

        if 'resolution' in self.shader_program.uniforms:
            self.change_res(width, height)

        super(ShaderWindow, self).on_resize(width, height)

        print(width, height)

    def set_behind_icons(self):
        progman = win32gui.FindWindow("Progman", None)
        result = win32gui.SendMessageTimeout(progman, 0x052c, 0, 0, 0x0, 1000)
        workerw = 0

        def _enum_windows(tophandle, topparamhandle):
            p = win32gui.FindWindowEx(tophandle, 0, "SHELLDLL_DefView", None)
            if p != 0:
                workerw = win32gui.FindWindowEx(0, tophandle, "WorkerW", None)

                pyglet_hwnd = self._hwnd
                # pyglet_hdc = win32gui.GetWindowDC(pyglet_hwnd)
                win32gui.SetParent(pyglet_hwnd, workerw)

            return True

        win32gui.EnumWindows(_enum_windows, 0)  # sets window behind icons

        self.set_location(0, 0)

    def _update_shader_time(self, dt):
        if 'time' in self.shader_program.uniforms:
            self.shader_program.uniforms.time += dt * self.timescale
        '''
        if 'backbuffer' in self.shader_program.uniforms:
            print(self.shader_program.uniforms.backbuffer)
            # fbo = gl.glGenFramebuffers(1)
            # glBindTexture(self.texture.target, self.texture.id)
            buffer = pyglet.image.get_buffer_manager().get_color_buffer().get_texture()
            print(buffer, buffer.target, buffer.tex_coords)
            self.shader_program.uniforms.backbuffer = buffer
        '''

        # mouse
        if self.update_mouse_pos:
            if 'mouse' in self.shader_program.uniforms:
                pos = win32api.GetCursorPos()

                nx = (pos[0]) / (self.width)
                ny = (self.height - pos[1]) / (self.height)
                self.shader_program.uniforms.mouse = (nx, ny)

    def change_update_rate(self, val):
        pyglet.clock.unschedule(self._update_shader_time)
        self.update_rate = val
        pyglet.clock.schedule_interval(self._update_shader_time, 1 / self.update_rate)

    def change_shader(self, shader_file):
        sf = open(shader_file)
        sf_json = json.loads(sf.read())
        frag_shader = sf_json['code']


        self.shader_program.use()
        # self.shader_program.clear()
        # del self.shader_program
        # self.shader_program = pyshaders.from_files_names(vert, shader_file)
        try:
            self.shader_program = pyshaders.from_string(vert_shader, frag_shader)
            self.shader_program.use()
        except pyshaders.ShaderCompilationError:
            print(f"error compiling shader {shader_file}")
            return False

        self.change_res(self.width, self.height)
        return True

    def change_res(self, w, h):
        if 'resolution' in self.shader_program.uniforms:
            self.shader_program.uniforms.resolution = (w, h)

    def copyFramebuffer(self, tex, *size):
        # if we are given a new size
        if len(size) == 2:
            # resize the texture to match
            tex.width, tex.height = size[0], size[1]

        # bind the texture
        gl.glBindTexture(tex.target, tex.id)
        # copy the framebuffer
        gl.glCopyTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA, 0, 0, tex.width, tex.height, 0)
        # unbind the texture
        gl.glBindTexture(tex.target, 0)




'''
@window.event
def on_draw():
    # gl.glEnable(gl.GL_DEPTH_TEST)
    # gl.glEnable(gl.GL_BLEND)
    # gl.glBlendFunc(gl.GL_ONE, gl.GL_ONE_MINUS_SRC_ALPHA)
    gl.glClearColor(0, 0, 0, 0)
    gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT)
    # vertex_list.draw(vert_mode)

    # window.clear()
    tris.draw(GL_TRIANGLES)
'''

if __name__ == '__main__':
    # style = pyglet.window.Window.WINDOW_STYLE_BORDERLESS
    window = ShaderWindow(width=960, height=540, resizable=False)
    pyglet.app.run()
