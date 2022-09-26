#Imports for M-LOOP
import mloop.interfaces as mli
import mloop.controllers as mlc
import mloop.visualizations as mlv
import pandas as pd
from scipy import io
import os
import numpy as np
import time
from scipy import integrate


alpha = 0.5
Time = 16.0


ARF = [0.15, 0.1, 0.15, 0.1, 0.05]
Amplitudes = [ 0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]


import datetime


#File path location
summaryDatLoc = "N:\KRbLab\M_loop\\2022_09\\"
writeFileLoc = "N:\KRbLab\M_loop\MLoopParam\param.mat"
CountFolderDirectory = "N:\KRbLab\M_loop\Counter"
SavePath = "N:\KRbLab\M_loop\Data\Run1.csv"
#Declare your custom class that inherits from the Interface class
class CustomInterface(mli.Interface):
    
    #Initialization of the interface, including this method is optional
    def __init__(self):
        #You must include the super command to call the parent class, Interface, constructor 
        super(CustomInterface,self).__init__()
        self.count = 1
        self.dict = {'Count': [], 'param': [], 'AtomNumber': [], 'pkOD': [], 'sigX': [], 'sigY': [],  'cost': []}

        self.Utility = Utils()
        #Attributes of the interface can be added here
        #If you want to precalculate any variables etc. this is the place to do it
        #In this example we will just define the location of the minimum

        
    #You must include the get_next_cost_dict method in your class
    #this method is called whenever M-LOOP wants to run an experiment
    def updateDict(self, count, params, pkOD, sigX, sigY, NRb, cost):
        self.dict['Count'].append(count)
        self.dict['param'].append(params)
        self.dict['AtomNumber'].append(NRb)
        self.dict['pkOD'].append(pkOD)
        self.dict['sigX'].append(sigX)
        self.dict['sigY'].append(sigY)
        self.dict['cost'].append(cost)
        self.Save()
    def Save(self):
        pd.DataFrame.from_dict(data=self.dict).to_csv(SavePath, columns =['Count', 'param', 'AtomNumber', 'pkOD','sigX', 'sigY', 'cost'])

    def get_next_cost_dict(self,params_dict):
        
        #Get parameters from the provided dictionary
        params = params_dict['params']


        #Writes param into param.mat which RFevap2Machine.m reads
        self.Utility.write(self.count, params) 
        
        
        #Writes File Such that while loop in matlab side iterates up
        file1 = open(CountFolderDirectory + f"\count{self.count}" +".txt", "w")
        toFile = "Write what you want into the field"
        file1.write(toFile)
        file1.close()

        print("Waiting for Data")
        dataOut = self.Utility.CheckCompletion()


        print("Analysing Data")
        #Data Analysis
        dataRb = dataOut['dataRb']
        pkOD, sigX, sigY, NRb = ExtractVal(dataRb)
        cost = costFinderLit(pkOD, NRb)
        #cost = costFinderODAvg(pkOD, sigX, sigY)



        bad = False

        #The cost, uncertainty and bad boolean must all be returned as a dictionary
        #You can include other variables you want to record as well if you want
        print("pKOD, NRb, Cost")
        print(pkOD, NRb, cost)
        print("================================================")

        self.updateDict(self.count, params, pkOD, sigX, sigY, NRb, cost)
        self.count += 1
        
        cost_dict = {'cost':cost, 'bad':bad}
        return cost_dict
def ExtractVal(dataRb):
    pkOD, sigX, sigY, NRb = float(dataRb[-1][3]), float(dataRb[-1][4]), float(dataRb[-1][5]), float(dataRb[-1][8])
    return pkOD, sigX, sigY, NRb

def costFinderLit(pkOD, NRb): #Background N Get File structure for more accurate
    N1 = 7376000.0/15 #or 7376000.0/100
    if NRb <= 0:
        return 0
    else:
        Fn = 2/(1 + np.exp(N1/NRb))
        return -Fn*pkOD**3*NRb**(alpha-9/5)
def costFinderODAvg( pkOD, sigX, sigY):
    twoDgauss = lambda y, x: pkOD*np.exp(-(x**2/(2*sigX**2) + y**2/(2*sigY**2)))
    Avg = integrate.dblquad(twoDgauss, -3*sigX, 3*sigX, -3*sigY, 3*sigY)[0]
    return -Avg
def costFinderpkOD(pkOD):
    return -pkOD*(1/100)

def clear():
    for f in os.listdir(CountFolderDirectory):
        os.remove(os.path.join(CountFolderDirectory, f))
 
class Utils():
    def __init__(self):
        x = datetime.datetime.now()
        self.prevDate = int(x.strftime("%d"))
        self.PrevDir = self.SumFileLoc()
        self.RunNumberStart = self.getRunNumber(self.PrevDir)

    def write(self, count, params):
        #Input Fcut (length = 5) tTotal (scalar) amp (length = 5) A (length = 15)
        io.savemat(writeFileLoc,{'count': count, 'fcut':params[0:5], 'tTotal': Time, 'amp': ARF, 'A': params[5:len(params)]})

    def read(self, dir): #Get File structure for more accurate
        mat = io.loadmat(dir)
        return mat
    def CheckCompletion(self):
        NotComplete = True
        while NotComplete :
            x = datetime.datetime.now()
            currentDate = int(x.strftime("%d"))
            RunNumber = self.getRunNumber(self.PrevDir)
            if RunNumber != self.RunNumberStart:
                self.RunNumberStart = RunNumber
                data = self.read(self.PrevDir)
                return data
            if currentDate > self.prevDate: #Add wait time and retry 
                print("MidNight")
                data = self.UpdateFileLoc()
                return data
            
            time.sleep(0.1)
    def UpdateFileLoc(self):
        x = datetime.datetime.now()
        currentDate = int(x.strftime("%d"))
        self.prevDate = currentDate
        NotExist = True
        while  NotExist:
            RunNumber = self.getRunNumber(self.PrevDir)

            if os.path.isfile(self.SumFileLoc()):
                self.PrevDir = self.SumFileLoc()
                self.RunNumberStart = self.getRunNumber(self.PrevDir)
                data = self.read(self.PrevDir)
                return data
            elif RunNumber > self.RunNumberStart:
                self.RunNumberStart = RunNumber
                data = self.read(self.PrevDir)

                time.sleep(60) #Data synch such that next file is created in new dir
                self.PrevDir = self.SumFileLoc()
                return data                





    def SumFileLoc(self): #Also restarts run Prev Number
        x = datetime.datetime.now()
        pathSumFile = summaryDatLoc +  x.strftime("%G") + '-' + x.strftime("%m") + '-' + x.strftime("%d") + "\summary_data_backup.mat"	
        

        return pathSumFile

    def getRunNumber(self, dir):
        check = 0
        while check == 0:
            if(os.path.isfile(dir)):

                mat = None
                while mat is None:
                    try:
                        # connect
                        mat = io.loadmat(dir)
                    except:
                        pass
                dataRb = mat['dataRb']

                return float(dataRb[-1][0])
            time.sleep(0.1)
def main():
    #M-LOOP can be run with three commands
    
    #First create your interface
    interface = CustomInterface()
    #Next create the controller. Provide it with your interface and any options you want to set
    
    #Specific: Machine Learning Type: Neural Net


    #Fitting all parameters
    '''
    init = [10, 5, 3, 2.3, 2.21, 0.15, 0.1, 0.15, 0.1, 0.05, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] #Check Init
    minB= [1.786, 1.786, 1.786, 1.786, 1.786, 0, 0, 0, 0, 0, -8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8]
    maxB = [19.9, 19.9, 19.9, 19.9, 19.9, 0.2, 0.2, 0.2, 0.2, 0.2, 8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8]
    '''

    #Fitting just the frequencies
    #init = [10, 5, 3, 2.3, 2.21]
    init = [10.54119461,  4.9748205,    3.25308527,   2.06068179,   1.84569306, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    minB= [1.786, 1.786, 1.786, 1.786, 1.786, -8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8]
    maxB = [19.9, 19.9, 19.9, 19.9, 19.9, 8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8]
    clear()

    controller = mlc.create_controller(interface, 
                                       controller_type = 'neural_net',
                                       no_delay = False, 
                                       max_num_runs = 800,
                                    
                                       #target_cost = -2.99,
                                       num_params = len(init), 
                                       min_boundary =  minB,
                                       max_boundary =  maxB,
                                       num_training_runs = 100, 
                                       first_params = init, 
                                       training_type = 'random')
                                       
    #To run M-LOOP and find the optimal parameters just use the controller method optimize
    controller.optimize()
    
    clear()
    #The results of the optimization will be saved to files and can also be accessed as attributes of the controller.
    print('Best parameters found:')
    print(controller.best_params)

    #You can also run the default sets of visualizations for the controller with one command
    mlv.show_all_default_visualizations(controller)
    

#Ensures main is run when this code is run as a script
if __name__ == '__main__':
    main()