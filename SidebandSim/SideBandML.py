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
import subprocess
from julia.api import Julia
import csv
jl = Julia(compiled_modules=False)

from julia import Main

csvName = 'result.csv'
SavePath = ".\RunSummary.csv"
#Declare your custom class that inherits from the Interface class
class CustomInterface(mli.Interface):
    
    #Initialization of the interface, including this method is optional
    def __init__(self):
        #You must include the super command to call the parent class, Interface, constructor 
        super(CustomInterface,self).__init__()
        self.count = 1
        self.dict = {'Count': [], 'param': [], 'ground_state': [], 'nbarx': [], 'cost': []}
        #Main.include("runSidebandSeq.jl")
        #self.Main = Main
        #Attributes of the interface can be added here
        #If you want to precalculate any variables etc. this is the place to do it
        #In this example we will just define the location of the minimum

        
    #You must include the get_next_cost_dict method in your class
    #this method is called whenever M-LOOP wants to run an experiment
    def updateDict(self, count, params, ground_state,nbarx,  cost):
        self.dict['Count'].append(count)
        self.dict['param'].append(params)
        self.dict['ground_state'].append(ground_state)
        self.dict['nbarx'].append(nbarx)
        self.dict['cost'].append(cost)
        self.Save()
    def Save(self):
        pd.DataFrame.from_dict(data=self.dict).to_csv(SavePath, columns =['Count', 'param', 'ground_state', 'nbarx','cost'])

    def get_next_cost_dict(self,params_dict):
        
        #Get parameters from the provided dictionary
        params = params_dict['params']
        #Main.include("runSidebandSeq.jl")

        #print(Main.add(1,2))

        '''
op_t = 28,op_f1_amp = 0.3,op_f2_amp = 0.06,
    r_t = 32,ax_t = 32,r_f1_amp =  1,r_f2_amp =  1,ax_f1_amp = 1,ax_f2_amp = 1,
    n1=8,n2=20,n3=10,n4=12,n5=14,n6=40
        '''
        op_t, op_f1_amp, op_f2_amp, r_t, ax_t, r_f1_amp, r_f2_amp, ax_f1_amp, ax_f2_amp = params
        n1, n2,n3,n4,n5,n6 = 8, 20, 10, 12, 14, 40
    
        passArg = ["julia", "runSideBandSeq.jl"] + list(params)+ [8, 20, 10, 12, 14, 40]
        for j, i in  enumerate(passArg):
            passArg[j] = str(i)
        test = subprocess.Popen(passArg, stdout=subprocess.PIPE)
        output = test.communicate()[0]
        print(output)

        ground_state, nbarx =getData()# 1, 2#self.Main.interface(op_t, op_f1_amp, op_f2_amp, r_t, ax_t, r_f1_amp, r_f2_amp, ax_f1_amp, ax_f2_amp, n1, n2,n3,n4,n5,n6)
        print(f'Ground State: {ground_state}; nbarx: {nbarx}')
        cost = costFinderLit(ground_state, nbarx)



        self.updateDict(self.count, params, ground_state,nbarx,  cost)
        self.count += 1
        bad = False 
        cost_dict = {'cost':cost, 'bad':bad}
        return cost_dict


def costFinderLit(ground_state, nbarx): #Background N Get File structure for more accurate
    if ground_state == 1:
        return -100
    else:
        return -(1/(1-ground_state))

def getData():
    with open(csvName) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        for line in csv_reader:
            data1, data2 = line
            return float(data1), float(data2)
def main():
    #M-LOOP can be run with three commands

    #First create your interface
    interface = CustomInterface()
    #Next create the controller. Provide it with your interface and any options you want to set
    
    #Specific: Machine Learning Type: Neural Net



    minB = [10, 0.01, 0.01, 10, 10, 0.01, 0.01, 0.01, 0.01]
    maxB = [50, 1, 1, 50, 50, 1, 1, 1, 1]
    init = [28, 0.3, 0.06, 32, 32, 1, 1, 1, 1]
    controller = mlc.create_controller(interface, 
                                       controller_type = 'neural_net',
                                       no_delay = False, 
                                       max_num_runs = 100,
                                    
                                       #target_cost = -2.99,
                                       num_params = len(init), 
                                       min_boundary =  minB,
                                       max_boundary =  maxB,
                                       num_training_runs = 10, 
                                       first_params = init, 
                                       training_type = 'random')
                                       
    #To run M-LOOP and find the optimal parameters just use the controller method optimize
    controller.optimize()

    #The results of the optimization will be saved to files and can also be accessed as attributes of the controller.
    print('Best parameters found:')
    print(controller.best_params)

    #You can also run the default sets of visualizations for the controller with one command
    mlv.show_all_default_visualizations(controller)
    

#Ensures main is run when this code is run as a script
if __name__ == '__main__':
    main()