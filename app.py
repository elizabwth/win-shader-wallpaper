import pyglet
from pyglet.gl import *
from pyglet import clock
from pyglet.window import key

import pyshaders
  
# Window creation
window = pyglet.window.Window(visible=True, width=640, height=480, resizable=True)

# Shader creation
vert = './shader/vert.glsl'
frag = './shader/frag.glsl'
shader = pyshaders.from_files_names(vert, frag)
shader.use()

shader.uniforms.resolution = (window.width, window.height)

vert_count = 12000
vert_mode = GL_TRIANGLES

vertex_list = pyglet.graphics.vertex_list(vert_count, 'v3f', 'c4B', 't2f', 'n3f')

def _update_shader_time(dt):
  #shader.uniforms.vertexCount = vert_count
  shader.uniforms.time += dt

pyglet.clock.schedule_interval(_update_shader_time, 0.0016)


@window.event
def on_draw(): 
  gl.glEnable(gl.GL_DEPTH_TEST)
  gl.glEnable(gl.GL_BLEND)
  gl.glBlendFunc(gl.GL_ONE, gl.GL_ONE_MINUS_SRC_ALPHA)
  gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT)

  vertex_list.draw(vert_mode)

@window.event
def on_mouse_motion(x, y, dx, dy):
  nx = -(-x + window.width/2)/(window.width/2)
  ny = -(-y + window.height/2)/(window.height/2)
  # normalized (-1 to 1)
  shader.uniforms.mouse = (nx, ny)


@window.event
def on_key_press(symbol, modifiers):
  print(shader.uniforms.time)
  if symbol == key.Q:
    pyglet.app.exit()

@window.event
def on_resize(width, height):
  shader.uniforms.resolution = (width, height)

if __name__ == '__main__':
  pyglet.app.run()
