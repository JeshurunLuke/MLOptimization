from scipy import io

def exportParamsEvap(params, Time, name):
    writeFileLoc = "Z:\KRbLab\M_Loop1.5\MLoopParam"  + "\\" + name

    io.savemat(writeFileLoc,{'count': 3, 'fcut':params[0:5], 'tTotal': Time, 'amp': params[5:10], 'A': params[10:len(params)]})
def exportParamsODT( params, name):
    writeFileLoc = "Z:\KRbLab\M_Loop1.5\MLoopParam"  + "\\" + name
    io.savemat(writeFileLoc,{'count': 2, 'newTODTPWR': params[0], 'RatioF':params[1:len(params)] })
