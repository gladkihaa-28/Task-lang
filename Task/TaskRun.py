import os
import time
from CompiledFiles import cmain

import sys
import os

def run(file_name):
    cmain.main(file_name, file_name)


if __name__ == "__main__":
    path = f"{sys.argv[1]}"
    run(path)
