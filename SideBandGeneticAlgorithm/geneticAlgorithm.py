import itertools
import math
import numpy as np
import random
import subprocess
import matplotlib.pyplot as plt
import csv
from joblib import Parallel, delayed
import multiprocessing
import os 
import time 
import pandas as pd
csvName = 'result.csv'
SavePath = "./RunSummary.csv"


#=========================================
# demonstrator for genetic algorithms: 
# How many guesses do we need to find 
# a specific sentence?
#=========================================


class GeneticEvolveSet:
    def ParallizeIt(self,  gen_curr,rate_mutation):
        gen_next = self.mutate(gen_curr,rate_mutation)  
        ground_state = self.Ejulia(gen_next)
        fit_next = self.getCost(ground_state)
        print(ground_state, fit_next, gen_next)
        return [gen_next, fit_next]
    def getCost(self, ground_state):
        return -(1/(1-ground_state))
    def mutate(self, gen_parent,rate_mutation):
        gen_child = ''
        seedRun = os.getpid() * int(time.time()) % 123456789
        local_state = np.random.RandomState(seedRun)
        for ind, char in enumerate(gen_parent):
            if (local_state.uniform() < rate_mutation):
                if ind%2 == 1:
                    char = str(local_state.choice([1, 2, 3, 4, 5], 1)[0])
                else:
                    char = str(local_state.choice([1, 2, 3], 1)[0])
            gen_child = gen_child+char
        return gen_child

    def evolve(self,Ejulia,  init,nchild,rate_mutation, Iterations):
        self.Ejulia = Ejulia
        gen_curr = init
        gsInital = Ejulia(gen_curr)
        fit_curr = self.getCost(gsInital)

        gen_best = gen_curr
        fit_best = fit_curr

        igen     = 0
        while (igen< Iterations):
            print("Starting Data Distri")
            data = Parallel(n_jobs=multiprocessing.cpu_count() )(delayed(self.ParallizeIt)( gen_best , rate_mutation) for i in range(nchild))
            genList, fitList = np.transpose(data)[0], [float(i) for i in np.transpose(data)[1]]

            for fit_curr, gen_curr in zip(fitList, genList):
                if fit_curr < fit_best:
                    print(f"The Updaters: {fit_curr, fit_best}")
                    fit_best = fit_curr
                    gen_best = gen_curr

            igen     = igen + 1 
            print('D')
            print("igen=%5i fit=%13.5e gen=%s" % (igen,float(fit_best),gen_best))
        return igen, gen_best, fit_best

#======================================
class EvolveSeq:
    def __init__(self):
        self.F1 = ''
        self.eVseq = ''
        self.F2 = ''
        self.Seq = self.initialize()
    
    @staticmethod
    def InitializeInterpreter(F1):
        preSeq = F1
        def InteractWithJulia(seq):
            seq = preSeq + seq
            passArg = ["julia", "runSideBandSeq.jl"] + [str(i) for i in seq]
            Run = subprocess.Popen(passArg, stdout=subprocess.PIPE)
            output = Run.communicate()[0]
            data= str(output).split(',')
            ground_state = float(data[1])
            return ground_state
        return InteractWithJulia

    def EvolveSet(self, learner):
        Iterations = 2
        nchild        = 30
        init = self.eVseq
        Ejulia = self.InitializeInterpreter(self.F1)
        rate_mutation = 0.1

        it, gen_best, fit_best  = learner(Ejulia, init, nchild,rate_mutation, Iterations)
        return gen_best

    def splitSeq(self, seq, n, i):
        x = [seq[i * n:(i + 1) * n] for i in range((len(seq) + n - 1) // n )]
        self.F1 = ''.join(list(itertools.chain.from_iterable(x[0:i])))
        self.eVseq = ''.join(list(itertools.chain.from_iterable(x[i])))

        self.F2 = ''.join(list(itertools.chain.from_iterable(x[(i+1):len(x)])))
        print(self.F1, self.eVseq)

    def Controller(self):
        evolver = GeneticEvolveSet()
        learner = evolver.evolve

        splitInto = 6
        Seq = [i for i in self.Seq]
        for i in range(math.ceil(len(Seq)/splitInto)):
            self.splitSeq(Seq,splitInto,i)
            gen_best = self.EvolveSet(learner)
            print(gen_best)
            print([i for i in self.F1] + [i for i in gen_best])
            Seq = [i for i in self.F1] + [i for i in gen_best] + [i for i in self.F2] 

        
#======================================
    def initialize(self):
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
    
s = EvolveSeq()
s.Controller()