from julia import Main
import quanestimation.StateOptimization.StateOptimization as stateopt
class StateOpt_DE(stateopt.StateOptSystem):
    def __init__(self, tspan, psi0, H0, dH=[], decay=[], W=[], \
                 popsize=10, ini_population=[], max_episode=1000, c=1.0, cr=0.5, seed=1234):

        stateopt.StateOptSystem.__init__(self, tspan, psi0, H0, dH, decay, W, accuracy=1e-8)
        
        """
        --------
        inputs
        --------
        popsize:
           --description: number of populations.
           --type: int

        ini_population:
           --description: initial state.
           --type: array

        max_episode:
            --description: max number of training episodes.
            --type: int
        
        c:
            --description: mutation constant.
            --type: float

        cr:
            --description: crossover constant.
            --type: float
        
        seed:
            --description: random seed.
            --type: int
        
        """
        if ini_population == []: 
            ini_population = [psi0]

        self.popsize = popsize
        self.ini_population = ini_population
        self.c = c
        self.cr = cr
        self.seed = seed
        self.max_episode = max_episode

    def QFIM(self, save_file):
        if self.gamma == [] or self.gamma[0] == 0.0:
            diffevo = Main.QuanEstimation.TimeIndepend_noiseless(self.freeHamiltonian, self.Hamiltonian_derivative, \
                                                                               self.psi0, self.tspan, self.W, self.accuracy)
            Main.QuanEstimation.DE_QFIM(diffevo, self.popsize, self.ini_population, self.c, self.cr, self.seed, self.max_episode, save_file)
        else:
            diffevo = Main.QuanEstimation.TimeIndepend_noise(self.freeHamiltonian, self.Hamiltonian_derivative, self.psi0, self.tspan, \
                        self.decay_opt, self.gamma, self.W, self.accuracy)
            Main.QuanEstimation.DE_QFIM(diffevo, self.popsize, self.ini_population, self.c, self.cr, self.seed, self.max_episode, save_file)
        self.load_save()

    def CFIM(self, Measurement, save_file):
        if self.gamma == [] or self.gamma[0] == 0.0:
            diffevo = Main.QuanEstimation.TimeIndepend_noiseless(self.freeHamiltonian, self.Hamiltonian_derivative, \
                                                                               self.psi0, self.tspan, self.W, self.accuracy)
            Main.QuanEstimation.DE_CFIM(Measurement, diffevo, self.popsize, self.ini_population, self.c, self.cr, self.seed, self.max_episode, save_file)
        else:
            diffevo = Main.QuanEstimation.TimeIndepend_noise(self.freeHamiltonian, self.Hamiltonian_derivative, self.psi0, self.tspan, \
                        self.decay_opt, self.gamma, self.W, self.accuracy)
            Main.QuanEstimation.DE_CFIM(Measurement, diffevo, self.popsize, self.ini_population, self.c, self.cr, self.seed, self.max_episode, save_file)
        self.load_save()
        