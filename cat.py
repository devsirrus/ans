#!/usr/bin/python3
import glob
import fileinput

path = "./file/"
merge_files = glob.glob(path + '*.txt')

with open("./cat_result.txt", "w") as f:
    cat_data = fileinput.input(merge_files)
    f.writelines(cat_data)
    f.flush()
    
