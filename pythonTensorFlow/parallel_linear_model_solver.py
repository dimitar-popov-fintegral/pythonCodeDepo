'''
:script pythonTensorFlow/parallel_linear_model_solver.py:
:description: The purpose is to write a gradient descent method with various learning rates
:date: 20170728
:author: D POPOV
'''

import tensorflow
import numpy
import multiprocess

'''
Define linear model and objective function
'''
# (W * x) + (b)
# Variables
W = tensorflow.Variable([1.], dtype=tensorflow.float32)
b = tensorflow.Variable([.1], dtype=tensorflow.float32)
# Input
x = tensorflow.placeholder(dtype=tensorflow.float32)
# Output
y = tensorflow.placeholder(dtype=tensorflow.float32)
# Model and MSE
LM = (W * x) + b
MSE = tensorflow.reduce_sum(tensorflow.square(LM-y))

'''
Function optimizer
'''
# Gradient Descent
lr = tensorflow.placeholder(dtype=tensorflow.float32)
optim = tensorflow.train.GradientDescentOptimizer(lr).minimize(MSE)

'''
Data - Training
'''
xTrain = [1,2,3,4]
yTrain = [i + numpy.pi for i in xTrain]

'''
Define function for parallel apply
'''
def parallel_gradient_descent(iterations, inputDict):
    init = tensorflow.global_variables_initializer()
    session = tensorflow.Session()
    session.run(init)
    for iter in range(iterations):
        session.run(optim, feed_dict=inputDict)
    # xTrain = inputDict.get(x)
    yTrain = inputDict.get(y)
    param_W, param_b, mse = session.run([W, b, MSE], feed_dict={x: [1,2,3,4], y: yTrain})
    output.put({'param_W':param_W, 'param_b': param_b, 'MSE': mse})
    return True

'''
Parallel initilization
'''
output = multiprocess.Queue()
feedDict = {lr: 0.1, x: xTrain, y: yTrain}
processes = [multiprocess.Process(target=parallel_gradient_descent, args=(1000, feedDict)) for x in range(1)]

for p in processes:
    p.start()

for p in processes:
    p.join()

results = [output.get() for p in processes]

print results