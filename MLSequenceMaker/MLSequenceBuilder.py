import itertools
import math
import numpy as np
import subprocess
from joblib import Parallel, delayed
import multiprocessing
import os 
import pandas as pd
import os
import mloop.interfaces as mli
import mloop.controllers as mlc
import pandas as pd
import os
import numpy as np
import subprocess

target_cost = -7
from utils import ArraytoSeq, SeqToArray, Convert2Learn


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
    def decodeMLOOP(self, params):
        seq = ''
        for p_i in params:
            seq = seq + str(p_i).split('.')[1]
        return seq
    def toMLOOP(self, pop_i, lenOfSeq, numOfParam):
        params = np.zeros(numOfParam)
        array_ind = np.arange(0, len(pop_i) + lenOfSeq, lenOfSeq, dtype = int)

        for ind, start_ind in enumerate(array_ind[0:len(array_ind)-1]):
            params[ind] = float("0." + "".join(list([str(i) for i in pop_i[start_ind:array_ind[ind+1]]])))
        return params
    
    def denormalizeFromRand(self,u):
        ind = self._bounds.shape[0]
        return np.array([int(ui*(self._bounds[i%ind,1]-self._bounds[i%ind,0])+self._bounds[i%ind,0]) for i, ui in enumerate(u)])


#Declare your custom class that inherits from the Interface class
class CustomInterface(mli.Interface):
    
    #Initialization of the interface, including this method is optional
    def __init__(self, cCST, lenOfSeq):
        #You must include the super command to call the parent class, Interface, constructor 
        super(CustomInterface,self).__init__()
        self.count = 1
        self.cCST = cCST
        self.lenOfSeq = lenOfSeq



    def get_next_cost_dict(self,params_dict):
        
        #Get parameters from the provided dictionary
        params = params_dict['params']

        print(np.array([format(round(i, self.lenOfSeq), f'.{self.lenOfSeq}f') for i in params], dtype= object))
        seq = self.cCST.decodeMLOOP(np.array([format(round(i, self.lenOfSeq), f'.{self.lenOfSeq}f') for i in params], dtype= object))
        print(seq)
        cost = self.cCST.eval(seq)


        self.count += 1
        bad = False 
        cost_dict = {'cost':cost, 'bad':bad}
        return cost_dict

def getCost( ground_state, UNC):
    quant = ground_state #- UNC
    if quant > 0:
        return -(1/(1-ground_state))
    else: 
        return 0

class ML():
    def __init__(self, numOfParam, splitInto):
        self.numOfParam = numOfParam
        self.LenOfSeq = splitInto//numOfParam
    def generateTrainingSet(self, init, cCST, totalRUN):
        self.bounds = cCST.bounds()
        ndim = len(init)

        pop  = np.zeros((ndim,totalRUN),dtype=int)
        rnd  = np.random.rand(ndim,totalRUN)
        for p in range(totalRUN):
            pop[:,p] = cCST.denormalizeFromRand(rnd[:,p])
        
        pop[:, 0] =  [int(i) for i in init]
        fit_curr = np.zeros(totalRUN)           # note that fit == 0.0 is best here,
        fit_curr[:] =  Parallel(backend='loky', n_jobs=multiprocessing.cpu_count())(delayed(cCST.eval)(pop[:,p]) for p in range(totalRUN))
        
        params = np.zeros((self.numOfParam, totalRUN), dtype = float)

        for p in range(totalRUN):

            params[:, p] = cCST.toMLOOP(pop[:, p], self.LenOfSeq, self.numOfParam)
        return Convert2Learn(np.transpose(params), fit_curr)

    def evolve(self, cCST, init, trainingSet, Iterations):
        maxB = list(np.ones(self.numOfParam)*0.949)
        minB = list(np.ones(self.numOfParam)*0.05)
                                                            
        saveName = self.generateTrainingSet(init,cCST, trainingSet)

        interface = CustomInterface(cCST, self.LenOfSeq)
        controller = mlc.create_controller(interface, 
                                        controller_type = 'neural_net',
                                        no_delay = False, 
                                        max_num_runs = Iterations,
                                        
                                        target_cost = target_cost, 
                                        num_params = int(self.numOfParam), 
                                        min_boundary =  minB,
                                        max_boundary =  maxB,
                                        num_training_runs = 2, 
                                        learner_archive_filename= saveName, 
                                        training_type = 'random')
        controller.optimize()
        paramSet, fit_best = controller.best_params, controller.best_cost
        return cCST.decodeMLOOP(np.array([format(round(i, self.LenOfSeq), f'.{self.LenOfSeq}f') for i in paramSet], dtype= object)), fit_best
class Control():

    def evolve(self, cCST, init, trainingSet, Iterations):
        fit_best = cCST.eval(init)
        return init, fit_best
    
class EvolveSeq:
    def __init__(self):
        self.F1 = ''
        self.eVseq = ''
        self.F2 = ''
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

    def EvolveSet(self, learner, bounds, translator ):
        Iterations = 120
        trainingSet        = 100

        init = self.eVseq
        Ejulia = self.InitializeInterpreter(self.F1, translator)
        cCST = Cost(getCost,bounds, Ejulia)

        gen_best, fit_best = learner.evolve(cCST, init, trainingSet, Iterations)

        QOI = 1/fit_best + 1


        return gen_best, fit_best, QOI

    def splitSeq(self, seq, n, i):
        x = [seq[i * n:(i + 1) * n] for i in range((len(seq) + n - 1) // n )]
        self.F1 = ''.join(list(itertools.chain.from_iterable(x[0:i])))
        self.eVseq = ''.join(list(itertools.chain.from_iterable(x[i])))
        self.F2 = ''.join(list(itertools.chain.from_iterable(x[(i+1):len(x)])))

    def clear(self, Directory):
        for f in os.listdir(Directory):
            os.remove(os.path.join(Directory, f))

    def GroupTranslator(self, seq, task):# 1 , 2, 3
        if task == 1: #Converts to what julia knows 
            return ArraytoSeq([int(i) for i in seq])
        elif task == 2: #Converts to what genetic algorithm knows
            return ''.join(list([str(i) for i in SeqToArray(seq)]))

    def Controller(self):
        expand = False

        numOfParam = 6
        splitInto = 6  #has to be multiple of numOfParam

        evolver = ML(numOfParam, splitInto)

        #evolver = Control()

        translator = self.GroupTranslator #CHANGE FOR SCHEME

        bounds = np.array([[0, 9]])      #CHANGE FOR SCHEME   

        #Initial =    translator(self.initialize(), 2)
        Initial = translator(self.initialize(), 2)
        if expand: 
            Iterations = 10
            ind = bounds.shape[0]
            u = np.random.uniform(0, 1, int(splitInto*Iterations))
            Extra = [str(int(ui*(bounds[i%ind,1]-bounds[i%ind,0])+bounds[i%ind,0])) for i, ui in enumerate(u)]
            start =  math.ceil(len(Initial)/splitInto)
        else:
            start = 1
            Extra = []


        Seq = [str(i) for i in Initial] + Extra
        for i in range(start, math.ceil(len(Seq)/splitInto)):

            print(f'{round(i/math.ceil(len(Seq)/splitInto), 2) *100} % Complete' )

            self.splitSeq(Seq,splitInto,i)

            gen_best, fit_best, ground_state = self.EvolveSet(evolver, bounds, translator)
            Seq = [i for i in self.F1] + [i for i in gen_best] + [i for i in self.F2] 
            print(''.join(list([i for i in self.F1] + [i for i in gen_best])),ground_state)

            self.updateDict(i, ''.join(list([i for i in self.F1] + [i for i in gen_best])), ground_state,  fit_best)
            if fit_best < target_cost:
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
        #769876987698769876987121111186214111481811118111116181116811111811181611111611111116115381116111811116618111111181111111611111
        #init = '222132312221323122213231222132312221323122111211111111113121121114111111143111311111111131111111111121113111111121311111111111311111113111211111111214211121111311111411'
        return init
if __name__ == '__main__':
    count = multiprocessing.cpu_count()
    if count > 11:
        print(f"More Cores than Bargened for {count}")
        pass
    else:
        s = EvolveSeq()
        s.Controller()