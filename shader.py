import pyglet
import pyshaders
from pyglet.gl import *


class ShaderWindow(pyglet.window.Window):
    def __init__(self, *args, **kwargs):
        super(ShaderWindow, self).__init__(*args, **kwargs)
        print("hwnd", self._hwnd)

        vert = './shader/vert.glsl'
        frag = './shader/frag/trees.glsl'
        self.shader_program = pyshaders.from_files_names(vert, frag)
        self.shader_program.use()

        tris = (-1, -1, -1, 1, 1, -1, 1, 1, -1, 1, 1, -1)
        self.polys = pyglet.graphics.vertex_list(6, ('v2f', tris))

        self.timescale = 1

        def _update_shader_time(dt):
            if 'time' in self.shader_program.uniforms:
                self.shader_program.uniforms.time += dt * self.timescale

        pyglet.clock.schedule_interval(_update_shader_time, 1 / 60)

    def change_shader(self, shader_file):
        vert = './shader/vert.glsl'
        del self.shader_program
        #self.shader_program.use()
        #self.shader_program.clear()
        self.shader_program = pyshaders.from_files_names(vert, shader_file)
        self.shader_program.use()

    def on_draw(self):
        gl.glEnable(gl.GL_DEPTH_TEST)
        # gl.glEnable(gl.GL_BLEND)
        gl.glClearColor(0, 0, 0, 1)
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT)
        # vertex_list.draw(vert_mode)

        # window.clear()
        self.polys.draw(GL_TRIANGLES)

    def on_resize(self, width, height):
        if 'resolution' in self.shader_program.uniforms:
            self.shader_program.uniforms.resolution = (width, height)



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
