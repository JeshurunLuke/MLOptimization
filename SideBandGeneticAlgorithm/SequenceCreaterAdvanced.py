import itertools
import math
from tokenize import Single, String
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
import os

from utils import ArraytoSeq, SeqToArray, SaveCSV


global csvMaker

write = True
stopCOST = -5


def getCost( ground_state, UNC):
    quant = ground_state #- UNC
    if quant > 0:
        return -(1/(1-ground_state))
    else: 
        return 0


class Cost:
    def __init__(self,fCST,bounds, exec):
        self._fcost  = fCST   # function pointer to cost function
        self._bounds = bounds # boundaries on which to evaluate cost function
                              # must be of form np.array([[lo1,up1],[lo2,up2]...[lon,upn]])
        #self._tol    = tol    # tolerance for difference between population members (see self.err)
        self.exec =  exec


    def eval(self, x):
        gen_next = ''.join([str(int(i)) for i in x])
        ground_state, gUNC = self.exec(gen_next)
        print(ground_state, gUNC)
        fit_next = self._fcost(ground_state, gUNC)
        return fit_next

    # returns the full range information
    def bounds(self):
        return self._bounds

    # returns the tolerance associated with cost function
    def maxmin(self):
        return self._maxmin

    # returns the tolerance associated with cost function
    def tol(self):
        return self._tol


    def denormalize(self,u):
        ind = self._bounds.shape[0]
        return np.array([int(ui*(self._bounds[i%ind,1]-self._bounds[i%ind,0])+self._bounds[i%ind,0]) for i, ui in enumerate(u)])


class GeneticAdvanced:
    def name(self):
        return 'Advanced'
    def mutate(self, gene, rate):
        gene_mod = ''
        seedRun = os.getpid() * int(time.time()) % 123456789
        local_state = np.random.RandomState(seedRun)
        for ind, char in enumerate(gene):
            if (local_state.uniform() < rate):
                char = str(local_state.choice(np.arange(self.bounds[ind%self.dim,0], self.bounds[ind%self.dim,0]+1), 1)[0])
            gene_mod = gene_mod+char
        return gene_mod
    def breed(self, parents,rate):
        iverb= 0# set to > 0 for diagnostic output

        sp1  = ''.join(list([str(i) for i in parents[:,0]]))
        sp2  = ''.join(list([str(i) for i in parents[:,1]]))
        # encoding: if p1 consists of three coordinates x1,x2,x3, sp1 will be x1x2x3 
        # (leading zeroes removed) 
        # Encoding consists of two steps: turn input into decimals (to remove exponents),
        # then turn these into strings.


        # crossover: Cut genome of parents at random position, swap.
        ig   = np.random.randint(0,len(sp1)-1)
        so1  = sp1[0:ig] + sp2[ig:len(sp1)]
        so2  = sp2[0:ig] + sp1[ig:len(sp1)]

        som1 = self.mutate(so1, rate)
        som2 = self.mutate(so2, rate)
        
        if (iverb):
            print('                           som1 = %s' % (so1))
            print('                           som2 = %s' % (so2))


        children      = np.zeros(parents.shape)  
        children[:,0] = np.array([int(i) for i in som1])
        children[:,1] = np.array([int(i) for i in som2])
        return children

    def stochastic_accept(self, weight):
        n    = weight.size
        weight = np.abs(weight)
        width = np.max(weight) - np.min(weight)

        rank = np.zeros(n,dtype=int)
        for j in range(n): # positions to be filled
            notfilled = True
            while (notfilled): 
                i = np.random.randint(0,n) # choose randomly a position
                if (np.random.uniform(0, 1) <= (weight[i] - np.min(weight))/width): # accept if its weight allows it
                    rank[j]   = i
                    notfilled = False
        print(rank)
        return rank
    def evolve(self, cCST,init, npop,rate,maxit, adaptRate = True):
        iverb = 1
        self.bounds = cCST.bounds()
        self.dim = int(np.array(self.bounds).shape[0])

        ndim = len(init)
        #tol  = cCST.tol()
        pop  = np.zeros((ndim,npop),dtype=int)
        rnd  = np.random.rand(ndim,npop)
        for p in range(npop):
            pop[:,p] = cCST.denormalize(rnd[:,p])
        pop[:, 0] =  [int(i) for i in init]
        fit_curr = np.zeros(npop)           # note that fit == 0.0 is best here,
        ind_breed= np.zeros(npop,dtype=int) # index of pop members to be bred
        ind_best = -1
        parents  = np.zeros((ndim,npop),dtype=int)    # normalized (parent) population
        children = np.zeros((ndim,npop),dtype=int)    # normalized (children) population
        fit_curr[:] =  Parallel(n_jobs=multiprocessing.cpu_count()-2)(delayed(cCST.eval)(pop[:,p]) for p in range(npop))
        ind_breed[:] = self.stochastic_accept(fit_curr)
        ind_best     = np.argmax(fit_curr)
        ind_wrst     = np.argmin(fit_curr)
        it = 0
    
        while ((it < maxit) and min(fit_curr)> stopCOST): 
            if adaptRate:
                R_n = rate*(15 - it)/15 if it < 10 else 0.02
                print(R_n)
            else:
                R_n = rate
            print(f'Progress = {round(it/maxit*100, 2)} % in iteration: {it}')
            #ind_wrst = ind_best # store for comparison in next iteration
            # (1) normalize genomes of parent population and rank them according to ind_breed
            for p in range(npop):
                parents[:,p] = pop[:,ind_breed[p]] 
            # (2) breed the parents
            for p in range(int(npop/2)): # only half the range, because breed needs pairs of parents
                children[:,2*p:2*(p+1)] = self.breed(parents[:,2*p:2*(p+1)],R_n) 
            # (3) denormalize genomes of children population and assign back
            for p in range(npop):
                pop[:,p] = children[:,p] 
            # (4) evaluate fitness of children and find ranking according to fitness
            fit_curr[:] = Parallel(n_jobs=multiprocessing.cpu_count()-2)(delayed(cCST.eval)(children[:,p]) for p in range(npop))
            ind_breed[:] = self.stochastic_accept(fit_curr)
            ind_best     = np.argmax(fit_curr) # find fittest member
            it           = it+1
            if (iverb == 1):
                print(f"Best Cost: {round(min(fit_curr), 3)} Ground state: {round(1/min(fit_curr) + 1, 2)}, Range: {round(min(fit_curr) - max(fit_curr), 3)}")
            if write:
                global csvMaker
                csvMaker.Save(Generation = it, Sequence = ''.join(list([str(i) for i in children[:,ind_best]])), Ground_state = round(1/min(fit_curr) + 1, 2) , Cost = round(min(fit_curr), 3))
        return ''.join(list([str(i) for i in children[:,ind_best]])),  min(fit_curr)



class GeneticEvolveSet:
    def name(self):
        return 'Basic'
    def ParallizeIt(self,  gen_curr,rate_mutation):
        gen_next = self.mutate(gen_curr,rate_mutation)  
        ground_state, groundUNC = self.Ejulia(gen_next)
        fit_next = getCost(ground_state, groundUNC)
        print(ground_state, fit_next, gen_next)
        return [gen_next, fit_next, ground_state]

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

    def evolve(self,Ejulia,  init,nchild,rate_mutation, Iterations, checkIn = False, adaptRate = False):
        self.Ejulia = Ejulia
        gen_curr = init
        gsInital, gsUNC = Ejulia(gen_curr)
        print(f"Starting Ground State: {gsInital} +/- {gsUNC}")
        fit_curr = getCost(gsInital, gsUNC)

        gen_best = gen_curr
        fit_best = fit_curr

        igen     = 0
        while (igen< Iterations and fit_curr> stopCOST):
            print("Starting Data Distri")
            if adaptRate:
                R_m = rate_mutation*(20 - Iterations)/20
            else:
                R_m = rate_mutation
            data = Parallel(n_jobs=multiprocessing.cpu_count()-2)(delayed(self.ParallizeIt)( gen_best , R_m) for i in range(nchild))
            genList, fitList, ground_state = np.transpose(data)[0], [float(i) for i in np.transpose(data)[1]], [float(i) for i in np.transpose(data)[2]]


            for fit_curr, gen_curr in zip(fitList, genList):
                if fit_curr < fit_best:
                    print(f"The Updaters: {fit_curr, fit_best}")
                    if checkIn:
                        gsCHECKIn, gsCHECKuncIn = Ejulia(gen_curr)
                        fit_curr = getCost(gsCHECKIn, gsCHECKuncIn) #REDONE
                    fit_best = fit_curr
                    gen_best = gen_curr
            gsCHECK, gsCHECKunc = Ejulia(gen_best)
            fit_best = getCost(gsCHECK, gsCHECKunc) #REDONE
            igen     = igen + 1 
            print("igen=%5i fit=%13.5e gen=%s" % (igen,float(fit_best),gen_best))
            if write:
                global csvMaker
                csvMaker.Save(Generation = igen, Sequence = gen_best, Ground_state = round(gsCHECK, 3) , Cost = round(fit_best, 3))
        return igen, gen_best, fit_best, gsCHECK

#======================================
class EvolveSeq:
    def __init__(self):
        self.F1 = ''
        self.eVseq = ''
        self.F2 = ''
        self.Seq = self.initialize()
        self.dict = {'i':[], 'Seq': [],  'ground_state': [], 'cost': []}

    def updateDict(self, count, params, ground_state,  cost):
        self.dict['i'].append(count)
        self.dict['Seq'].append(params)
        self.dict['ground_state'].append(ground_state)
        self.dict['cost'].append(cost)
        self.Save()
    def Save(self):
        SavePath = "./SeqCreaterSum.csv"
        pd.DataFrame.from_dict(data=self.dict).to_csv(SavePath, columns =['i', 'Seq', 'ground_state','cost'])

    @staticmethod
    def InitializeInterpreter(F1, translator):
        preSeq = F1
        def InteractWithJulia(seq):
            seq = translator(preSeq, 1) + translator(seq, 1)
            #print(seq)
            passArg = ["julia", "runSideBandSeq.jl"] + [str(i) for i in seq]
            Run = subprocess.Popen(passArg, stdout=subprocess.PIPE)
            output = Run.communicate()[0]
            data= str(output).split(',')
            ground_state, groundUNC = float(data[1]), float(data[2])
            return ground_state, groundUNC
        return InteractWithJulia

    def EvolveSet(self, learner, bounds, translator):
        Iterations = 20
        nchild        = 44
        init = self.eVseq
        Ejulia = self.InitializeInterpreter(self.F1, translator)
        if learner.name() == 'Advanced':
            rate_mutation = 0.10
            cCST = Cost(getCost,bounds, Ejulia)
            gen_best, fit_best = learner.evolve(cCST,init, nchild,rate_mutation,Iterations,  adaptRate = True)
            QOI = -1/fit_best + 1
        elif learner.name()  == 'Basic':
            rate_mutation = 0.2

            it, gen_best, fit_best, QOI  = learner.evolve(Ejulia, init, nchild,rate_mutation, Iterations)
        return gen_best, fit_best, QOI

    def splitSeq(self, seq, n, i):
        x = [seq[i * n:(i + 1) * n] for i in range((len(seq) + n - 1) // n )]
        self.F1 = ''.join(list(itertools.chain.from_iterable(x[0:i])))
        self.eVseq = ''.join(list(itertools.chain.from_iterable(x[i])))

        self.F2 = ''.join(list(itertools.chain.from_iterable(x[(i+1):len(x)])))

    def clear(self, Directory):
        for f in os.listdir(Directory):
            os.remove(os.path.join(Directory, f))
    def Singletranslator(self, seq, task):
        if task == 1: #Converts back
            return seq
        elif task == 2: 
            return seq
    def GroupTranslator(self, seq, task):# 1 , 2, 3
        if task == 1: #Converts to what julia knows 
            return ArraytoSeq([int(i) for i in seq])
        elif task == 2: #Converts to what genetic algorithm knows
            return ''.join(list([str(i) for i in SeqToArray(seq)]))

    def Controller(self):
        TempDir = './Temp'
        if not os.path.exists(TempDir):
            os.mkdir('./Temp')
        self.clear(TempDir)

        evolver = GeneticAdvanced()
        translator = self.GroupTranslator #CHANGE FOR SCHEME

        bounds = np.array([[1,3], [1, 5]])  
        bounds = np.array([[1, 9]])      #CHANGE FOR SCHEME   

        
        splitInto = 7  #has to be even number #CHANGE FOR SCHEME
        Seq = [i for i in translator(self.Seq, 2)]
        print(len(Seq), len(self.Seq))
        for i in range(3, math.ceil(len(Seq)/splitInto)):
            if write:
                global csvMaker
                saveIt = TempDir + f'//Iteration{i}.csv'
                csvMaker = SaveCSV(['Generation', 'Sequence', 'Ground_state', 'Cost'], saveIt)
            print(f'{round(i/math.ceil(len(Seq)/splitInto), 2) *100} % Complete' )

            self.splitSeq(Seq,splitInto,i)
            gen_best, fit_best, ground_state = self.EvolveSet(evolver, bounds, translator)
            Seq = [i for i in self.F1] + [i for i in gen_best] + [i for i in self.F2] 
            print(''.join(list([i for i in self.F1] + [i for i in gen_best])),ground_state)

            self.updateDict(i, ''.join(list([i for i in self.F1] + [i for i in gen_best])), ground_state,  fit_best)
            if fit_best < stopCOST:
                return ''.join(list([i for i in self.F1] + [i for i in gen_best]))

    
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