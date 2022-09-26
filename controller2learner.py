import mloop.utilities as mlu
import numpy as np
convert_dict = {}
def Convert2Learn(training_filename, TransformCost = 2):
    training_dict = mlu.get_dict_from_file(
        training_filename,
    )
    allParams = np.array(training_dict['out_params'], dtype=float) 
    convert_dict['all_params'] = np.array(training_dict['out_params'], dtype=float) 
    if np.sum(TransformCost) != 2:
        all_cost = mlu.safe_cast_to_array(TransformCost)
    else:
        all_cost = mlu.safe_cast_to_array(training_dict['in_costs'])
    convert_dict['all_costs'] = all_cost
    convert_dict['costs_count'] = training_dict['num_in_costs']
    convert_dict['all_uncers'] = mlu.safe_cast_to_array(1E-8*np.ones(len(convert_dict['all_costs'])))
    
    convert_dict['bad_run_indexs'] = get_bads(training_dict)
    convert_dict['best_index'] = int(np.argmin(all_cost))
    convert_dict['best_cost'] = all_cost[convert_dict['best_index']]
    convert_dict['best_params'] = allParams[convert_dict['best_index']]
    convert_dict['archive_type'] = 'Trainer'
    convert_dict['params_count'] = training_dict['num_params']
    # best_index

    # best_cost

    convert_dict['worst_index'] = int(np.argmax(all_cost))
    convert_dict['worst_cost'] = all_cost[convert_dict['worst_index']]
    
    convert_dict['cost_range'] = convert_dict['worst_cost'] - convert_dict['best_cost']

    nameIsolate =training_filename.split('/')[-1]
    nameSplit = nameIsolate.split('_')
    nameSplit[0] = 'learnerC'
    name = '_'.join(nameSplit)    
    training_dict.update(convert_dict)
    saveName =f'./ConversionFolder/{name}' 
    mlu.dict_to_txt_file(training_dict, saveName)
    return saveName
    
def get_bads(training_dict):
    bad_run_index = []
    badarray = training_dict['in_bads']
    for i, State in enumerate(badarray):
        if State == True:
            bad_run_index.append(i)
            
    return bad_run_index