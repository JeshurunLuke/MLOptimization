
import numpy as np
import pandas as pd


Translator = {1: '11', 2: '12', 3: '13', 4: '14', 5: '15', 6: '21', 7: '22',8: '31', 9:'32'}

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
