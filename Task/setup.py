from distutils.core import setup
from Cython.Build import cythonize

setup(ext_modules=cythonize('/home/alexander/PycharmProjects/Task-programming-lang/Task/CompiledFiles/CParser.pyx'))