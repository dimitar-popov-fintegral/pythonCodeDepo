'''
:author: D POPOV
:description: The purpose of this code is to construct some example code for parallel tools in Python
'''

import numpy
import pandas
import multiprocess
import random

'''
:function functionToSquareRandomSeries:
:description: This function creates a uniform random sequence of length x
:argument x: The length of the random number sequence
'''
def functionToSquareRandomSeries(x, output):
    y = [random.random() for item in range(1,x)]
    output.put(y)

output = multiprocess.Queue()
processes = [multiprocess.Process(target=functionToSquareRandomSeries, args=(1000, output)) for x in range(4)]


for p in processes:
    p.start()

for p in processes:
    p.join()

results = [output.get() for p in processes]

print results

'''
:results: parallelized simple program for creating random numbers
'''