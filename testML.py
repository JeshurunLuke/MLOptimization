#Imports for python 2 compatibility
from __future__ import absolute_import, division, print_function
__metaclass__ = type

#Imports for M-LOOP
import mloop.interfaces as mli
import mloop.controllers as mlc
import mloop.visualizations as mlv
from controller2learner import Convert2Learn

#Other imports
import numpy as np
import time
import pandas as pd

minB  =  [1.785, 1.785, 1.785]#, 1.785, 1.785, 4, 0, 0, 0, 0, 0, -8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8]
maxB = [20, 20, 20]#,  20, 20, 16, 0.5, 0.5, 0.5, 0.5, 0.5, 8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8]


#Declare your custom class that inherits from the Interface class
class CustomInterface(mli.Interface):
    
    #Initialization of the interface, including this method is optional
    def __init__(self):
        #You must include the super command to call the parent class, Interface, constructor 
        super(CustomInterface,self).__init__()
        
        #Attributes of the interface can be added here
        #If you want to precalculate any variables etc. this is the place to do it
        #In this example we will just define the location of the minimum
        self.dict = {'Count': [], 'param': [], 'Cost': []}
        self.count = 1
        self.minimum_params = (np.array(minB)+ np.array(maxB))/2 #np.array([0,0.1,-0.1])
    
    def UpdateDic(self, count, param, cost):
        self.dict['Count'].append(count)
        self.dict['param'].append(param)
        self.dict['Cost'].append(cost)
        self.save()
    def save(self):
        pd.DataFrame.from_dict(data=self.dict).to_csv('dict_file.csv', columns =['Count', 'param', 'Cost'])
    #You must include the get_next_cost_dict method in your class
    #this method is called whenever M-LOOP wants to run an experiment
    def get_next_cost_dict(self,params_dict):
        
        #Get parameters from the provided dictionary
        params = params_dict['params']
        
        #Here you can include the code to run your experiment given a particular set of parameters
        #In this example we will just evaluate a sum of sinc functions
        cost = -np.sum(np.sinc(np.array(params) - self.minimum_params))

        #There is no uncertainty in our result
        uncer = 0
        #The evaluation will always be a success
        bad = False
        #Add a small time delay to mimic a real experiment
        self.UpdateDic(self.count, params, cost)
        #The cost, uncertainty and bad boolean must all be returned as a dictionary
        #You can include other variables you want to record as well if you want
        cost_dict = {'cost':cost, 'uncer':uncer, 'bad':bad}
        self.count +=1 
        return cost_dict
    
def main():
    #M-LOOP can be run with three commands
    
    #First create your interface
    interface = CustomInterface()
    
    train_name = './M-LOOP_archives/controller_archive_2022-09-19_09-45.txt'
    train_file = Convert2Learn(train_name)
    #Next create the controller. Provide it with your interface and any options you want to set
    controller = mlc.create_controller(interface, 
                                       controller_type='neural_net',
                                       no_delay = False, 
                                       max_num_runs = 15,
                                       #target_cost = -2.99,
                                       num_params = len(minB), 
                                       min_boundary = minB,
                                       max_boundary = maxB,
                                       num_training_runs = 2, 
                                       training_filename = train_file, 
                                       training_type = 'differential_evolution')
    #To run M-LOOP and find the optimal parameters just use the controller method optimize
    controller.optimize()
    
    #The results of the optimization will be saved to files and can also be accessed as attributes of the controller.
    print('Best parameters found:')
    print(controller.best_params)
    print((np.array(minB)+ np.array(maxB))/2)

    #You can also run the default sets of visualizations for the controller with one command
    mlv.show_all_default_visualizations(controller)
    

#Ensures main is run when this code is run as a script
if __name__ == '__main__':
    main()