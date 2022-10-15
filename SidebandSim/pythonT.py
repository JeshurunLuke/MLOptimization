import csv
'''
from julia.api import Julia
jl = Julia(compiled_modules=False)
from julia import Main
Main.println("I'm printing from a Julia function!")
class Test():
    def __init__(self):
        Main.include("runSidebandSeq.jl")
        self.Main = Main
    def trial(self):
        op_t, op_f1_amp, op_f2_amp, r_t, ax_t, r_f1_amp, r_f2_amp, ax_f1_amp, ax_f2_amp = [28.0,   0.3,  0.06, 32.0,    32.0,    1.0,     1.0,     1.0,     1.0,  ]
        n1, n2,n3,n4,n5,n6 = 8, 20, 10, 12, 14, 40
        print(Main.add(1,2))
        ground_state, nbarx = self.Main.interface(op_t, op_f1_amp, op_f2_amp, r_t, ax_t, r_f1_amp, r_f2_amp, ax_f1_amp, ax_f2_amp, n1, n2,n3,n4,n5,n6)
        print(ground_state)
tester = Test()
tester.trial()
'''
''''''
import subprocess
'''
test = subprocess.Popen(["julia", "runSideBandSeq.jl"], stdout=subprocess.PIPE)
output = test.communicate()[0]
print(output)
with open('result.csv') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    print(csv_reader)
    for line in csv_reader:
        data1, data2 = line
        print(data1)
        print(type(data1))
'''
passArgs = ['julia', 'runSideBandSeq.jl', '28.0', '0.3', '0.06', '32.0', '32.0', '1.0', '1.0', '1.0', '1.0', '8', '20', '10', '12', '14', '40']
test = subprocess.Popen(passArgs, stdout=subprocess.PIPE)
output = test.communicate()[0]
print(output)