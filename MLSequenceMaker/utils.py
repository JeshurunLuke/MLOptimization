
import numpy as np
import pandas as pd

from difflib import SequenceMatcher

Translator = {0: '33', 1: '11', 2: '12', 3: '13', 4: '14', 5: '15', 6: '21', 7: '22',8: '31', 9:'32'}

def ArraytoSeq(Array): #array is [1:,]
    seqTransformed = ''
    for i in Array:
        seqTransformed  = seqTransformed + Translator[int(i)]
   
    return seqTransformed

def SeqToArray(Seq): #Seq is a string
    key_list = list(Translator.keys())
    val_list = list(Translator.values())
    Array = []
    for pulse in range(0, len(Seq)-1, 2):
        pos  = val_list.index(Seq[pulse:pulse + 2])
        Array.append(int(key_list[pos]))
    return np.array(Array, dtype= int)
def Array2String(Array):
    return ''.join(list([str(i) for i in Array]))
def similarStrings(a, b):
    return SequenceMatcher(None, a, b).ratio()
class SaveCSV:
    def __init__(self, dictArgs, SavePath):
        self.dict = {}
        self.dictArgs = dictArgs
        self.SavePath = SavePath
        for i in dictArgs:
            self.dict[i] = []    
    
    def Save(self, **kwargs):
        for key, value in kwargs.items():
            self.dict[str(key)].append(value)
        pd.DataFrame.from_dict(data=self.dict).to_csv(self.SavePath, columns = self.dictArgs)
import mloop.utilities as mlu
import numpy as np
convert_dict = {}

def Convert2Learn(parameters, cost):
    print(parameters)
    allParams = np.array(parameters, dtype=float) 
    convert_dict['all_params'] = allParams #np.array(training_dict['out_params'], dtype=float) 

    convert_dict['all_costs'] = cost
    convert_dict['costs_count'] = len(cost)
    convert_dict['all_uncers'] = mlu.safe_cast_to_array(1E-8*np.ones(len(convert_dict['all_costs'])))
    
    convert_dict['bad_run_indexs'] = get_bads(len(cost))
    convert_dict['best_index'] = int(np.argmin(cost))
    convert_dict['best_cost'] = cost[convert_dict['best_index']]
    convert_dict['best_params'] = allParams[convert_dict['best_index']]
    convert_dict['archive_type'] = 'Trainer'
    convert_dict['params_count'] = len(parameters[0])
    # best_index

    # best_cost

    convert_dict['worst_index'] = int(np.argmax(cost))
    convert_dict['worst_cost'] = cost[convert_dict['worst_index']]
    
    convert_dict['cost_range'] = convert_dict['worst_cost'] - convert_dict['best_cost']


    saveName =f'./TrainingSet.txt' 
    mlu.dict_to_txt_file(convert_dict, saveName)
    return saveName
    
def get_bads(length):
    bad_run_index = []
    badarray = [False for i in range(length)]
    for i, State in enumerate(badarray):
        if State == True:
            bad_run_index.append(i)
            
    return bad_run_index
