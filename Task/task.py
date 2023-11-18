import os
import time
import sys
import os

def run(file_name):
    os.system("python ./Task/TaskRun.py " + file_name)


if __name__ == "__main__":
    path = f"{sys.argv[1]}"
    run(path)
