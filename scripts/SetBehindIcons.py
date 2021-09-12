from godot import exposed, export
from godot import *
import win32gui
import win32api

@exposed
class SetBehindIcons(Node):

	# member variables here, example:
	# a = export(int)
	# b = export(str, default='foo')
	_hwnd = OS.get_native_handle(2) # 2 = OS::WINDOW_HANDLE

	def _ready(self):
		"""
		Called every time the node is added to the scene.
		Initialization here.
		"""
		self.set_behind_icons(self.fill_screen)
		pass
	
	def fill_screen(self):
		OS.window_borderless = True
		OS.window_position = Vector2(0, 0)
		OS.window_size = OS.get_screen_size()
		
	def set_behind_icons(self, cb):
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
		cb()
