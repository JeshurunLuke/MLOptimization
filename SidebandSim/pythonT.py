from julia.api import Julia
jl = Julia(compiled_modules=False)
from julia import Main
Main.println("I'm printing from a Julia function!")
class Test():
    def __init__(self):
        Main.include("runSidebandSeq.jl")
        self.Main = Main
    def trial(self):
        a, b = self.Main.interface([1,2,3])
        print(a)
tester = Test()
tester.trial()