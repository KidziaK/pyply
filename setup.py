from setuptools import setup, Extension
from pathlib import Path

from builder import ZigBuilder

pyply = Extension("pyply", sources=["pyplymodule.zig"])

setup(
    name="pyply",
    version="0.0.1",
    url="https://github.com/KidziaK/pyply",
    description="PLY Parser for Python 3.6+ written in zig.",
    ext_modules=[pyply],
    cmdclass={"build_ext": ZigBuilder}
)

