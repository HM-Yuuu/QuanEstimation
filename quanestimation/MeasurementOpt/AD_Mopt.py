import numpy as np
from julia import Main
import warnings
import quanestimation.MeasurementOpt.MeasurementStruct as Measurement

class AD_Mopt(Measurement.MeasurementSystem):
    def __init__(self, mtype, minput, tspan, rho0, H0, dH, Hc=[], ctrl=[], decay=[], W=[], Adam=False, \
                 measurement0=[], max_episode=300, epsilon=0.01, beta1=0.90, beta2=0.99, seed=1234, load=False):

        Measurement.MeasurementSystem.__init__(self, mtype, minput, tspan, rho0, H0, dH, Hc, ctrl, decay, W, measurement0, seed, load, eps=1e-8)
        
        """
        --------
        inputs
        --------
        Adam:
            --description: whether to use Adam to update the controls.
            --type: bool (True or False)
            
        measurement0:
           --description: initial guess of measurements.
           --type: array

        max_episode:
            --description: max number of the training episodes.
            --type: int

        epsilon:
            --description: learning rate.
            --type: float

        beta1:
            --description: the exponential decay rate for the first moment estimates .
            --type: float

        beta2:
            --description: the exponential decay rate for the second moment estimates .
            --type: float

        eps:
            --description: calculation eps.
            --type: float
        
        """
        self.Adam = Adam
        self.max_episode = max_episode
        self.epsilon = epsilon
        self.beta1 = beta1
        self.beta2 = beta2
        self.mt = 0.0
        self.vt = 0.0 
        self.seed = seed
        self.update_basis = 50
        
    def CFIM(self, save_file=False):
        """
        Description: use particle autodifferential algorithm to update the measurements that maximize the 
                     CFI (1/Tr(WF^{-1} with F the CFIM).

        ---------
        Inputs
        ---------
        save_file:
            --description: True: save the measurements for each episode but overwrite in the next episode and all the CFI (Tr(WF^{-1})).
                           False: save the measurements for the last episode and all the CFI (Tr(WF^{-1})).
            --type: bool
        """
        
        if self.mtype=="projection":
            warnings.warn("AD is not available when mtype is projection. Supported methods are 'PSO' and 'DE'.", DeprecationWarning)

        elif self.mtype=="input":
            ad = Main.QuanEstimation.LinearComb_Mopt(self.freeHamiltonian, self.Hamiltonian_derivative, self.rho0, self.tspan,\
                                                    self.decay_opt, self.gamma, self.povm_basis, self.M_num, self.W, self.eps)
            Main.QuanEstimation.CFIM_AD_Mopt(ad, self.mt, self.vt, self.epsilon, self.beta1, self.beta2, self.max_episode, self.Adam, save_file, self.seed)
            self.load_save()

        elif self.mtype=="rotation":
            ad = Main.QuanEstimation.RotateBasis_Mopt(self.freeHamiltonian, self.Hamiltonian_derivative, self.rho0, self.tspan,\
                                                    self.decay_opt, self.gamma, self.povm_basis, self.W, self.eps)
            Main.QuanEstimation.CFIM_AD_Mopt(ad, self.mt, self.vt, self.epsilon, self.beta1, self.beta2, self.max_episode, self.Adam, save_file, self.seed)
            self.load_save()
        else:
            raise ValueError("{!r} is not a valid value for method, supported values are 'projection' and 'input'.".format(self.mtype))