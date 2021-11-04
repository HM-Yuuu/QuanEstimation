
import numpy as np
import warnings
import math
from julia import Main

class Lindblad:
    """
    General dynamics of density matrices in the form of time local Lindblad master equation.
    {\partial_t \rho} = -i[H, \rho] + \sum_n {\gamma_n} {Ln.rho.Ln^{\dagger}
                 -0.5(rho.Ln^{\dagger}.Ln+Ln^{\dagger}.Ln.rho)}.
    """

    def __init__(self, tspan, rho_initial, H0, dH, Liouville_operator=[], gamma=[], Hc=[], ctrl_initial=[], control_option=True):
        """
        ----------
        Inputs
        ----------
        tspan: 
           --description: time series.
           --type: array
        
        rho_initial: 
           --description: initial state (density matrix).
           --type: matrix
        
        H0: 
           --description: free Hamiltonian.
           --type: matrix
           
        Hc: 
           --description: control Hamiltonian.
           --type: list (of matrix)
        
        dH: 
           --description: derivatives of Hamiltonian on all parameters to
                          be estimated. For example, dH[0] is the derivative
                          vector on the first parameter.
           --type: list (of matrix)
           
        ctrl_initial: 
           --description: control coefficients.
           --type: list (of array)
           
        Liouville operator:
           --description: Liouville operator in Lindblad master equation.
           --type: list (of matrix)    
           
        gamma:
           --description: decay rates.
           --type: list (of float number)
           
        control_option:   
           --description: if True, add controls to physical system.
           --type: bool
        """
        
        if type(dH) != list:
            raise TypeError('The derivative of Hamiltonian should be a list!')    
        
        if len(gamma) != len(Liouville_operator):
            raise TypeError('The length of decay rates and the length of Liouville operator should be the same!')

        if Hc == []:
            Hc = [np.zeros((len(H0), len(H0)))]

        if ctrl_initial == []:
            ctrl_initial = [np.zeros(len(tspan))]
        
        if dH == []:
            dH = [np.zeros((len(H0), len(H0)))]

        if Liouville_operator == []:
            Liouville_operator = [np.zeros((len(H0), len(H0)))]

        if gamma == []:
            gamma = [0.0]

        self.tspan = tspan
        self.rho_initial = np.array(rho_initial,dtype=np.complex128)
        self.freeHamiltonian = np.array(H0,dtype=np.complex128)
        self.control_Hamiltonian = [np.array(x,dtype=np.complex128) for x in Hc]
        self.Hamiltonian_derivative = [np.array(x,dtype=np.complex128) for x in dH]
        self.control_coefficients = ctrl_initial
        self.Liouville_operator = [np.array(x, dtype=np.complex128) for x in Liouville_operator]
        self.gamma = gamma
        self.control_option = control_option
        
        ctrl_length = len(self.control_coefficients)
        ctrlnum = len(self.control_Hamiltonian)
        if ctrlnum < ctrl_length:
            raise TypeError('There are %d control Hamiltonians but %d coefficients sequences: \
                                too many coefficients sequences'%(ctrlnum,ctrl_length))
        elif ctrlnum > ctrl_length:
            warnings.warn('Not enough coefficients sequences: there are %d control Hamiltonians \
                            but %d coefficients sequences. The rest of the control sequences are\
                            set to be 0.'%(ctrlnum,ctrl_length), DeprecationWarning)
        
        number = math.ceil(len(self.tspan)/len(self.control_coefficients[0]))
        if len(self.tspan) % len(self.control_coefficients[0]) != 0:
            self.tnum = number*len(self.control_coefficients[0])
            self.tspan = np.linspace(self.tspan[0], self.tspan[-1], self.tnum)


    def expm(self):
        if len(self.Hamiltonian_derivative) == 1:
            rho, drho = Main.QuanEstimation.expm(self.freeHamiltonian, self.Hamiltonian_derivative[0], self.rho_initial, self.Liouville_operator, \
                                 self.gamma, self.control_Hamiltonian, self.control_coefficients, self.tspan)
        else:
            rho, drho = Main.QuanEstimation.expm(self.freeHamiltonian, self.Hamiltonian_derivative, self.rho_initial, self.Liouville_operator, \
                                 self.gamma, self.control_Hamiltonian, self.control_coefficients, self.tspan)
        return rho, drho
                        

