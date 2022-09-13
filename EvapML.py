import numpy as np
#Imports for M-LOOP
import mloop.interfaces as mli
import mloop.controllers as mlc
import mloop.visualizations as mlv
from scipy import io
import matlab.engine
import os
#Other imports
import numpy as np
import time

alpha = -3
Time = 16 
#Declare your custom class that inherits from the Interface class
class CustomInterface(mli.Interface):
    
    #Initialization of the interface, including this method is optional
    def __init__(self):
        #You must include the super command to call the parent class, Interface, constructor 
        super(CustomInterface,self).__init__()
        
        #Attributes of the interface can be added here
        #If you want to precalculate any variables etc. this is the place to do it
        #In this example we will just define the location of the minimum

        
    #You must include the get_next_cost_dict method in your class
    #this method is called whenever M-LOOP wants to run an experiment
    def get_next_cost_dict(self,params_dict):
        
        #Get parameters from the provided dictionary
        params = params_dict['params']


        #Writes param into param.mat which RFevap2Machine.m reads
        write(params) 
        #names = matlab.engine.find_matlab()
        #eng = matlab.engine.connect_matlab(names[0])
        #eng.runScan("@mainHighB", 4, 'random', 1)
        
        path  = rf"{os.getcwd()}".encode('unicode_escape').decode()
        os.system(f"matlab -nosplash -nodesktop -r \"cd('{path}'), runScan(@mainHighB, 4, 'random', 1), exit\"")
        #eng.quit()

        dataOut = read()
        cost = costFinder(dataOut)

        
        '''
        writeTest(params)
        eng = matlab.engine.connect_matlab()

        eng.RFevap2Machine(1)
        eng.quit()

        #dataOut = read()
        cost = costFinderTest()
        '''

        #The evaluation will always be a success
        bad = False
        #Add a small time delay to mimic a real experiment
        #time.sleep(1)
        
        #The cost, uncertainty and bad boolean must all be returned as a dictionary
        #You can include other variables you want to record as well if you want
        cost_dict = {'cost':cost, 'bad':bad}
        return cost_dict
    
def write(params):
    #Input Fcut (length = 5) tTotal (scalar) amp (length = 5) A (length = 15)
    io.savemat('param.mat',{'fcut':params[0:5], 'tTotal': Time, 'amp': params[5:10], 'A': params[10:len(params)]})
def costFinder(data): #Background N Get File structure for more accurate
    dataRb = data['dataRb']
    pkOD, NRb = float(dataRb[-1][3]), float(dataRb[-1][8])
    return -pkOD**3*NRb**(alpha-9/5)
def read(): #Get File structure for more accurate
    mat = io.loadmat('./2022-05-05/summary_data.mat')
    return mat


'''
def writeTest(params):
    #Input Fcut (length = 5) tTotal (scalar) amp (length = 5) A (length = 15)

    io.savemat('test.mat',{'fcut':params[0:5], 'tTotal': params[5], 'amp': params[6:11], 'A': params[11:len(params)]})


def costFinderTest():
    mat = io.loadmat('./2022-05-05/mat1.mat')
    return mat['ans'][0][-1]    

'''

def main():
    #M-LOOP can be run with three commands
    
    #First create your interface
    interface = CustomInterface()
    #Next create the controller. Provide it with your interface and any options you want to set
    
    #Specific: Machine Learning Type: Neural Net
    init = [10, 5, 3, 2.3, 2.21, 0.15, 0.1, 0.15, 0.1, 0.05, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    minB= [1.785, 1.785, 1.785, 1.785, 1.785, 0, 0, 0, 0, 0, -8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8,-8]
    maxB = [20, 20, 20, 20, 20, 0.5, 0.5, 0.5, 0.5, 0.5, 8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8]
    controller = mlc.create_controller(interface, 
                                       controller_type = 'neural_net',
                                       max_num_runs = 1000,
                                       #target_cost = -2.99,
                                       num_params = len(init), 
                                       min_boundary =  minB,
                                       max_boundary =  maxB,
                                       num_training_runs = 100, 
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