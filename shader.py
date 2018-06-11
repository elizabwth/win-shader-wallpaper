import pyglet
import pyshaders
import win32gui
from pyglet.gl import *


class ShaderWindow(pyglet.window.Window):
    def __init__(self, *args, **kwargs):
        super(ShaderWindow, self).__init__(*args, **kwargs)
        print("hwnd", self._hwnd)

        vert = './shader/vert.glsl'
        frag = './shader/frag/trees.glsl'
        self.shader_program = pyshaders.from_files_names(vert, frag)
        self.shader_program.use()

        tris = (-1, -1, -1, 1, 2, -1, 1, 1, -1, 1, 1, -1)
        self.polys = pyglet.graphics.vertex_list(6, ('v2f', tris))

        self.timescale = 1
        self.update_rate = 120

        pyglet.clock.schedule_interval(self._update_shader_time,
                                       1 / self.update_rate)

        # progman = win32gui.FindWindow("Progman", None)
        # result = win32gui.SendMessageTimeout(progman, 0x052c, 0, 0, 0x0, 1000)
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

    def _update_shader_time(self, dt):
        if 'time' in self.shader_program.uniforms:
            self.shader_program.uniforms.time += dt * self.timescale

    def change_update_rate(self, val):
        pyglet.clock.unschedule(self._update_shader_time)
        self.update_rate = val
        pyglet.clock.schedule_interval(self._update_shader_time, 1 / self.update_rate)

    def change_shader(self, shader_file):
        vert = './shader/vert.glsl'

        self.shader_program.use()
        self.shader_program.clear()
        del self.shader_program
        self.shader_program = pyshaders.from_files_names(vert, shader_file)
        self.shader_program.use()

        self.change_res(self.width, self.height)

    def change_res(self, w, h):
        if 'resolution' in self.shader_program.uniforms:
            self.shader_program.uniforms.resolution = (w, h)

    def on_draw(self):
        # gl.glEnable(gl.GL_DEPTH_TEST)
        # gl.glEnable(gl.GL_BLEND)
        gl.glClearColor(0, 0, 0, 1)
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT)
        # vertex_list.draw(vert_mode)

        # window.clear()
        self.polys.draw(GL_TRIANGLES)

    def on_resize(self, width, height):
        if 'resolution' in self.shader_program.uniforms:
            self.change_res(width, height)

        super(ShaderWindow, self).on_resize(width, height)

        print(width, height)



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
