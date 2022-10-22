import numpy 
import numpy as np
def stochastic_universal_selection( fitness, num_parents):

    """
    Selects the parents using the stochastic universal selection technique. Later, these parents will mate to produce the offspring.
    It accepts 2 parameters:
        -fitness: The fitness values of the solutions in the current population.
        -num_parents: The number of parents to be selected.
    It returns an array of the selected parents.
    """

    fitness_sum = numpy.sum(fitness)
    if fitness_sum == 0:
        raise ZeroDivisionError("Cannot proceed because the sum of fitness values is zero. Cannot divide by zero.")
    probs = fitness / fitness_sum
    probs_start = numpy.zeros(probs.shape, dtype=numpy.float) # An array holding the start values of the ranges of probabilities.
    probs_end = numpy.zeros(probs.shape, dtype=numpy.float) # An array holding the end values of the ranges of probabilities.

    curr = 0.0

    # Calculating the probabilities of the solutions to form a roulette wheel.
    for _ in range(probs.shape[0]):
        min_probs_idx = numpy.where(probs == numpy.min(probs))[0][0]
        probs_start[min_probs_idx] = curr
        curr = curr + probs[min_probs_idx]
        probs_end[min_probs_idx] = curr
        probs[min_probs_idx] = 99999999999

    pointers_distance = 1.0 / len(fitness) # Distance between different pointers
    first_pointer = numpy.random.uniform(low=0.0, high=pointers_distance, size=1) # Location of the first pointer.

    # Selecting the best individuals in the current generation as parents for producing the offspring of the next generation.

    parents_indices = []

    for parent_num in range(num_parents):
        rand_pointer = first_pointer + parent_num*pointers_distance
        for idx in range(probs.shape[0]):
            if (rand_pointer >= probs_start[idx] and rand_pointer < probs_end[idx]):
                parents_indices.append(idx)
                break
    return parents_indices

def stochastic_accept( weight):
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
    return rank