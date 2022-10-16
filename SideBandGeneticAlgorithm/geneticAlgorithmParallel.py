import numpy as np
import random
import subprocess
import matplotlib.pyplot as plt
import csv
from joblib import Parallel, delayed
import multiprocessing
csvName = 'result.csv'


#=========================================
# demonstrator for genetic algorithms: 
# How many guesses do we need to find 
# a specific sentence?
#=========================================
# mutates a few genes, depending on mutation rate
def mutate(gen_parent,rate_mutation):
    gen_child = ''
    for ind, char in enumerate(gen_parent):
        if (random.random() < rate_mutation):
            if ind%2 == 1:
                char = random.choice('12345')
            else:
                char = random.choice('123')
        gen_child = gen_child+char
    return gen_child

#=========================================
# measures the fitness
def cost(gen_curr):
    gen_goal = '3142314'
    return sum(gen_curr[i] == gen_goal[i] for i in range(len(gen_goal)))/len(gen_curr)

def evaluate(seq):

    passArg = ["julia", "runSideBandSeq.jl"] + [str(i) for i in seq]
    Run = subprocess.Popen(passArg, stdout=subprocess.PIPE)
    output = Run.communicate()[0]
    data= str(output).split(',')
    ground_state = float(data[1])
    return -(1/(1-ground_state))

#=========================================
# evolve(gen_str,gen_goal,nchild,fFIT)
# evolves generations until goal is met
#-----------------------------------------
def evolve(init,nchild,Eval,rate_mutation, Iterations):
    gen_curr = init
    fit_curr = Eval(gen_curr)
    
    gen_best = gen_curr
    fit_best = fit_curr

    igen     = 0
    while (igen< Iterations):
        print("Starting Data Distri")
        data = Parallel(n_jobs=multiprocessing.cpu_count() )(delayed(ParallizeIt)(Eval, gen_best ,rate_mutation) for i in range(nchild))
        genList, fitList = np.transpose(data)[0], [float(i) for i in np.transpose(data)[1]]

        for fit_curr, gen_curr in zip(fitList, genList):
            print(fit_curr, gen_curr)
            if fit_curr < fit_best:
                print(f"The Updaters: {fit_curr, fit_best}")
                fit_best = fit_curr
                gen_best = gen_curr

        igen     = igen + 1 
        print('D')
        print("igen=%5i fit=%13.5e gen=%s" % (igen,float(fit_best),gen_best))
    return igen, gen_best, fit_best

def ParallizeIt(Eval, gen_curr,rate_mutation):
    gen_next = mutate(gen_curr,rate_mutation)  
    fit_next = Eval(gen_next)

    return [gen_next, fit_next]
#======================================
def main():
    Iterations = 100
    nchild        = 30
    init = initialize()
    fFIT          = evaluate
    rate_mutation = 0.01

    it, gen_best, fit_best  = evolve(init,nchild,fFIT,rate_mutation, Iterations)
    

    
#======================================
def initialize():
    init = ''
    for i in range(8):
        init += '22213231' 

    for i in range(20):
        init += '2131'

    
    for i in range(10):
        init += '1514222115143231' 

    
    for i in range(12):
        init += '1413222114133231'


    for i in range(14):
        init += '1312222113123231'

    for i in range(40):
        init += '1211222112113231'
    return init
main()
    
