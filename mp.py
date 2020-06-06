#!/usr/bin/python3
from multiprocessing import Process
import time

def test(hostname):
    time.sleep(3)
    print(str(hostname) + " finshed")

if __name__ == "__main__":
    list = [ i for i in range(1000)]

    for i in list:
        p = Process(target=test, args=(i,))
        p.start()
    else:
        p.join()
        print("end")
