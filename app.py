import pyglet
from pyglet.gl import *
from pyglet import clock
from pyglet.window import key

import pyshaders

import win32gui

# Window creation
style = pyglet.window.Window.WINDOW_STYLE_BORDERLESS
window = pyglet.window.Window(width=960, height=540, style=style, resizable=False)
#window.set_size(640, 480)
window.set_size(1920, 1080)

# set behind icons

progman = win32gui.FindWindow("Progman", None)
result = win32gui.SendMessageTimeout(progman, 0x052c, 0, 0, 0x0, 1000)

workerw = 0
def _enum_windows(tophandle, topparamhandle):
  p = win32gui.FindWindowEx(tophandle, 0, "SHELLDLL_DefView", None)
  if p != 0:
    workerw = win32gui.FindWindowEx(0, tophandle, "WorkerW", None)

    pyglet_hwnd = window._hwnd
    pyglet_hdc = win32gui.GetWindowDC(pyglet_hwnd)
    win32gui.SetParent(pyglet_hwnd, workerw)

  return True

win32gui.EnumWindows(_enum_windows, 0) # sets window behind icons

# Shader creation
vert = './shader/vert.glsl'
frag = './shader/frag/5.glsl'
shader = pyshaders.from_files_names(vert, frag)
shader.use()


def _update_shader_time(dt):
  if 'time' in shader.uniforms:
    shader.uniforms.time += dt*0.5

pyglet.clock.schedule_interval(_update_shader_time, 0.0016)


vert_count = 70000
vert_mode = GL_TRIANGLES
vertex_list = pyglet.graphics.vertex_list(vert_count, 'v3f', 'c4B', 't2f', 'n3f')

if 'vertexCount' in shader.uniforms:
  shader.uniforms.vertexCount = vert_count

tris = pyglet.graphics.vertex_list(6,
  ('v2f', (-1, -1, -1, 1, 1, -1, 1, 1, -1, 1, 1, -1))
)

@window.event
def on_draw(): 
  #gl.glEnable(gl.GL_DEPTH_TEST)
  #gl.glEnable(gl.GL_BLEND)
  #gl.glBlendFunc(gl.GL_ONE, gl.GL_ONE_MINUS_SRC_ALPHA)
  gl.glClearColor(0, 0, 0, 0)
  gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT)
  #vertex_list.draw(vert_mode)

  #window.clear()
  tris.draw(GL_TRIANGLES)

@window.event
def on_mouse_motion(x, y, dx, dy):
  nx = -(-x + window.width/2)/(window.width/2)
  ny = -(-y + window.height/2)/(window.height/2)
  # normalized (-1 to 1)
  if 'mouse' in shader.uniforms:
    shader.uniforms['mouse'] == (nx, ny)


@window.event
def on_key_press(symbol, modifiers):
  if 'time' in shader.uniforms:
    print(shader.uniforms.time)
  if symbol == key.Q:
    pyglet.app.exit()

@window.event
def on_resize(width, height):
  if 'resolution' in shader.uniforms:
    shader.uniforms.resolution = (width, height)

if __name__ == '__main__':
  pyglet.app.run()
