def generateTrainingSet(self, init, cCST, totalRUN):
    self.bounds = cCST.bounds()
    ndim = len(init)

    pop  = np.zeros((ndim,totalRUN),dtype=int)
    rnd  = np.random.rand(ndim,totalRUN)
    for p in range(totalRUN):
        pop[:,p] = cCST.denormalizeFromRand(rnd[:,p])
    
    pop[:, 0] =  [int(i) for i in init]
    fit_curr = np.zeros(totalRUN)           # note that fit == 0.0 is best here,
    fit_curr[:] =  Parallel(n_jobs=multiprocessing.cpu_count()-2)(delayed(cCST.eval)(pop[:,p]) for p in range(totalRUN))
    
    params = np.zeros((self.numOfParam, totalRUN), dtype = float)

    for p in range(totalRUN):

        params[:, p] = cCST.toMLOOP(pop[:, p], self.LenOfSeq, self.numOfParam)
    return Convert2Learn(np.transpose(params), fit_curr)
if __name__ == '__main__':
    generateTraining
