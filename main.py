import sys
import glob
from PyQt5 import QtWidgets, QtGui, uic
from PyQt5.QtCore import QTimer
import qtmodern.styles
import qtmodern.windows


import pyglet
import shader


class MyWindow(QtWidgets.QMainWindow):
    def __init__(self):
        super(MyWindow, self).__init__()
        uic.loadUi('main.ui', self)

        self.list_of_shaders = glob.glob('.\\shader\\glslsandbox\\*.glsl')

        self.shaderComboBox.addItems([s.split('\\')[-1] for s in self.list_of_shaders])
        self.shaderComboBox.currentIndexChanged.connect(self.change_shader)
        self.timescaleSlider.valueChanged.connect(self.update_timescale)
        self.updateRateSlider.valueChanged.connect(self.update_update_rate)
        self.setResButton.clicked.connect(self.update_resolution)

        self.mouseCheckBox.stateChanged.connect(self.update_mouse_input)

        self.resWidth.setValidator(QtGui.QIntValidator())
        self.resHeight.setValidator(QtGui.QIntValidator())

        self.forceButton.clicked.connect(self.force_clicked)

        # style = pyglet.window.Window.WINDOW_STYLE_BORDERLESS
        self.sw = shader.ShaderWindow(width=960, height=540, resizable=True)
        self.timer = QTimer()
        self.timer.timeout.connect(self.pyglet_loop)
        self.timer.start(0)

        self.resWidth.setText(str(self.sw.screen.width))
        self.resHeight.setText(str(self.sw.screen.height))
        # self.show()

    def update_mouse_input(self, state):
        print(state)
        if state == 0:
            self.sw.update_mouse_pos = False
        elif state == 2:
            self.sw.update_mouse_pos = True

    def update_resolution(self):
        self.sw.set_size(int(self.resWidth.text()), int(self.resHeight.text()))

    def force_clicked(self):
        self.sw.set_behind_icons()

    def update_timescale(self, val):
        new_val = val * 0.001
        self.sw.timescale = new_val
        self.timescaleLabel.setText(str(new_val))

    def update_update_rate(self, val):
        self.sw.change_update_rate(val)
        self.updateRateLabel.setText(str(val)+" FPS")

    def change_shader(self, index):
        shader = self.list_of_shaders[index]
        result = self.sw.change_shader(shader)
        self.currentShaderLabel.setText(shader.split('\\')[-1])
        if result:
            self.currentShaderLabel.setStyleSheet("QLabel { color : green; }")
            self.statusbar.showMessage('compiled successfully')
        if not result:
            self.currentShaderLabel.setStyleSheet("QLabel { color : red; }")
            self.statusbar.showMessage('error compiling shader')
        print(index)

    def pyglet_loop(self):
        pyglet.app.run()

    def closeEvent(self, event):
        pyglet.app.exit()


if __name__ == '__main__':
    app = QtWidgets.QApplication(sys.argv)
    window = MyWindow()

    # "modern" style
    qtmodern.styles.dark(app)
    mw = qtmodern.windows.ModernWindow(window)
    mw.show()

    # window.show()
    sys.exit(app.exec_())
