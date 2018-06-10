import sys
import glob
from PyQt5 import QtWidgets, uic
from PyQt5.QtCore import QTimer

import pyglet
import shader


class MyWindow(QtWidgets.QMainWindow):
    def __init__(self):
        super(MyWindow, self).__init__()
        uic.loadUi('main.ui', self)

        self.list_of_shaders = glob.glob('.\\shader\\frag\\*.glsl')

        self.shaderComboBox.addItems(self.list_of_shaders)
        self.shaderComboBox.currentIndexChanged.connect(self.change_shader)
        self.timescaleSlider.valueChanged.connect(self.update_timescale)


        self.sw = shader.ShaderWindow(width=960, height=540, resizable=True)
        self.timer = QTimer()
        self.timer.timeout.connect(self.pyglet_loop)
        self.timer.start(0)

        self.show()

    def update_timescale(self, val):
        new_val = val*0.01
        self.sw.timescale = new_val
        print(val)

    def change_shader(self, index):
        shader = self.list_of_shaders[index]
        self.sw.change_shader(shader)
        self.currentShaderLabel.setText(shader.split('\\')[-1])
        print(index)

    def pyglet_loop(self):
        pyglet.app.run()


if __name__ == '__main__':
    app = QtWidgets.QApplication(sys.argv)
    window = MyWindow()
    sys.exit(app.exec_())
