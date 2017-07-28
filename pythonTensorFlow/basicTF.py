'''
:script basicTF.py:
:description: The purpose is to begin with a short introduction to TF
:date: 20170728
:author: D POPOV
'''

import tensorflow
import numpy
import random
import multiprocess

# for reporduciability, set the seed
random.seed(1001)

'''
Nodes are crucial to development in TF create some now and invoke them using the so-called session interface
'''
node1 = tensorflow.constant(numpy.pi)
node2 = tensorflow.constant(numpy.e)

# session create
sesh = tensorflow.Session()

# to execute/run
print(sesh.run([node1, node2]))

'''
Elaborating on the node construction; we build several functions, also as nodes using TF
'''
# simple addition function
node3 = node1 + node2

# making a function which accepts inputs as standard
a = tensorflow.placeholder(tensorflow.float32,(2,2), 'holderTwoByTwo')
b = tensorflow.placeholder(tensorflow.float32,(2,2), 'holderTwoByTwo')
matrix_addition_node = tensorflow.add(a,b)

# test the output
# mat1, mat2 were not used in the coputation as TF throws an error in this case
mat1 = tensorflow.constant(value=[[1,2], [2,1]], shape=(2,2))
mat2 = tensorflow.constant(value=[[1,1], [1,1]], shape=(2,2))
print(sesh.run(matrix_addition_node, {a:[[1,2], [2,1]], b:[[1,2], [2,1]]}))

'''
Exploring the use of variables
'''
# write a simple linear model
# W * x + b
W = tensorflow.Variable([1], dtype = tensorflow.float32)
x = tensorflow.placeholder(dtype = tensorflow.float32)
b = tensorflow.Variable([numpy.pi], dtype = tensorflow.float32)
# learning rate param: https://stackoverflow.com/questions/33919948/how-to-set-adaptive-learning-rate-for-gradientdescentoptimizer
lr = tensorflow.placeholder(dtype=tensorflow.float32, shape=[])
y = tensorflow.placeholder(dtype=tensorflow.float32)
linear_model = (W * x) + b

# init of variables is required
init = tensorflow.global_variables_initializer()
sesh.run(init)

# fit model to x-values provided
evalList = [float(times) for times in [1,2,3,4]]
print(sesh.run(linear_model, {x: evalList}))

# evaluate fit
residualNode = tensorflow.reduce_sum(tensorflow.square(linear_model - y))
print("Error: ",sesh.run(residualNode, {x: evalList, y: [1 + (numpy.pi) for item in evalList]}))


'''
Gradient descent optimizer parallel - Does not function correctly 
'''
# initilize a simple gradient descent optimizer
optim = tensorflow.train.GradientDescentOptimizer(learning_rate=lr).minimize(residualNode)

# init problem
init = tensorflow.global_variables_initializer()
sesh.run(init)

# function to parallelize
def iterate_tensor_flow_optimization(iterations, queue, feedDict):
    for iter in range(iterations):
        sesh.run(optim, feed_dict=feedDict)
    queue.put(sesh.run([W, b]))
    return True

# init parallel procedure
learningRateVector = [float(item) for item in [.01, .1, .2, .5]]
x_ = [random.random() for i in range(4)] #[float(x) for x in [1, 2, 3, 4]]
y_ = [val + numpy.pi for val in x_]
queue = multiprocess.Queue()
processes = [multiprocess.Process(target=iterate_tensor_flow_optimization, args=(1000, queue, {y: y_, lr: learningRateVector[x]})) for x in range(2)]

# run
for p in processes:
    p.start()

for p in processes:
    p.join()

results = [queue.get() for p in processes]