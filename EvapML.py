#Imports for M-LOOP
import mloop.interfaces as mli
import mloop.controllers as mlc
import mloop.visualizations as mlv
from scipy import io
import os
import numpy as np
import time

alpha = 0.5
Time = 16.0


ARF = [0.15, 0.1, 0.15, 0.1, 0.05]
Amplitudes = [ 0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]


import datetime


#File path location
summaryDatLoc = "N:\KRbLab\M_loop\\2022_09\\"
writeFileLoc = "N:\KRbLab\M_loop\MLoopParam\param.mat"
CountFolderDirectory = "N:\KRbLab\M_loop\Counter"

#Declare your custom class that inherits from the Interface class
class CustomInterface(mli.Interface):
    
    #Initialization of the interface, including this method is optional
    def __init__(self):
        #You must include the super command to call the parent class, Interface, constructor 
        super(CustomInterface,self).__init__()
        self.count = 1
        self.Utility = Utils()
        #Attributes of the interface can be added here
        #If you want to precalculate any variables etc. this is the place to do it
        #In this example we will just define the location of the minimum

        
    #You must include the get_next_cost_dict method in your class
    #this method is called whenever M-LOOP wants to run an experiment
    def get_next_cost_dict(self,params_dict):
        
        #Get parameters from the provided dictionary
        params = params_dict['params']


        #Writes param into param.mat which RFevap2Machine.m reads
        self.Utility.write(self.count, params) 
        
        file1 = open(CountFolderDirectory + f"\count{self.count}" +".txt", "w")
        toFile = "Write what you want into the field"
        file1.write(toFile)
        file1.close()

        print("Waiting for Data")
        self.Utility.CheckCompletion()


        dataOut = self.Utility.read()
        cost = costFinder(dataOut)

        print("================================================")
        #The evaluation will always be a success
        bad = False

        #The cost, uncertainty and bad boolean must all be returned as a dictionary
        #You can include other variables you want to record as well if you want
        self.count += 1
        cost_dict = {'cost':cost, 'bad':bad}
        return cost_dict
def costFinder(data): #Background N Get File structure for more accurate
    dataRb = data['dataRb']

    N1 = 7376000.0/15 #or 7376000.0/100
    pkOD, NRb = float(dataRb[-1][3]), float(dataRb[-1][8])
    if NRb <= 0:
        return 0
    else:
        print("Cost Function Param")
        print(pkOD, NRb)
        Fn = 2/(1 + np.exp(N1/NRb))
        return -Fn*pkOD**3*NRb**(alpha-9/5)
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

    def read(self): #Get File structure for more accurate
        mat = io.loadmat(self.SumFileLoc())
        return mat
    def CheckCompletion(self):
        NotComplete = True
        while NotComplete :
            x = datetime.datetime.now()
            currentDate = int(x.strftime("%d"))
            RunNumber = self.getRunNumber(self.PrevDir)
            if RunNumber > self.RunNumberStart:
                print("RunNumber")
                print(RunNumber)
                print("Prev NumberStart")
                print(self.RunNumberStart)
                self.RunNumberStart = RunNumber
                NotComplete = False
            if currentDate > self.prevDate: #Add wait time and retry 
                print("MidNight")
                self.UpdateFileLoc()
                NotComplete = False
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
                NotExist = False
            elif RunNumber > self.RunNumberStart:
                self.RunNumberStart = RunNumber
                time.sleep(60)
                self.PrevDir = self.SumFileLoc()
                NotExist = False






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
                        print("Attempting")

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