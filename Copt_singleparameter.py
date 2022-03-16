from quanestimation import *
import numpy as np

# initial state
rho0 = 0.5 * np.array([[1.0, 1.0], [1.0, 1.0]])
# Hamiltonian
omega0 = 1.0
sx = np.array([[0.0, 1.0], [1.0, 0.0]])
sy = np.array([[0.0, -1.0j], [1.0j, 0.0]])
sz = np.array([[1.0, 0.0], [0.0, -1.0]])
H0 = 0.5 * omega0 * sz
dH = [0.5 * sz]
Hc = [sx, sy, sz]
# measurement
M1 = 0.5 * np.array([[1.0, 1.0], [1.0, 1.0]])
M2 = 0.5 * np.array([[1.0, -1.0], [-1.0, 1.0]])
M = [M1, M2]
# dissipation
sp = np.array([[0.0, 1.0], [0.0, 0.0]])
sm = np.array([[0.0, 0.0], [1.0, 0.0]])
decay = [[sp, 0.0], [sm, 0.1]]
# dynamics
tspan = np.linspace(0.0, 10.0, 250)
# initial control coefficients
cnum = len(tspan) - 1
ctrl0 = [np.array([np.zeros(cnum), np.zeros(cnum), np.zeros(cnum)])]
#
# # control algorithm: GRAPE
# GRAPE_paras = {"Adam":False, "ctrl0":ctrl0, "max_episode":50, "epsilon":0.01, "beta1":0.90, "beta2":0.99}
# control = ControlOpt(tspan, rho0, H0, dH, Hc, decay=decay, ctrl_bound=[-2.0, 2.0], save_file=False, \
#                      method="GRAPE", **GRAPE_paras)
# # take QFIM as the target function
# control.QFIM()
# # take CFIM as the target function
# control.CFIM(M)
# # take HCRB as the target function
# control.HCRB()

# # control algorithm: auto-GRAPE
# auto_GRAPE_paras = {"Adam":False, "ctrl0":ctrl0, "max_episode":50, "epsilon":0.01, "beta1":0.90, "beta2":0.99}
# control = ControlOpt(save_file=False, method="auto-GRAPE", **auto_GRAPE_paras)
# control.dynamics(
#     tspan,
#     rho0,
#     H0,
#     dH,
#     Hc,
#     decay=decay,
#     ctrl_bound=[-2.0, 2.0],
# )
# # take QFIM as the target function
# # control.QFIM()
# # take CFIM as the target function
# control.CFIM(M)
# # # take HCRB as the target function
# # control.HCRB()

# # control algorithm: PSO
# PSO_paras = {"particle_num":10, "ctrl0":[], "max_episode":[100,10], "c0":1.0, "c1":2.0, "c2":2.0, "seed":1234}
# control = ControlOpt(save_file=False, method="PSO", **PSO_paras)
# # take QFIM as the target function
# control.QFIM()
# # take CFIM as the target function
# control.CFIM(M)
# # take HCRB as the target function
# control.HCRB()

# # control algorithm: DE
# DE_paras = {
#     "popsize": 10,
#     "ctrl0": ctrl0,
#     "max_episode": 10,
#     "c": 1.0,
#     "cr": 0.5,
#     "seed": 1234,
# }
# control = ControlOpt(save_file=False, method="DE", **DE_paras)
# control.dynamics(
#     tspan,
#     rho0,
#     H0,
#     dH,
#     Hc,
#     decay=decay,
#     ctrl_bound=[-2.0, 2.0],
# )
# take QFIM as the target function
# control.QFIM()
# take CFIM as the target function
# control.CFIM(M)
# # take HCRB as the target function
# control.HCRB()

# control algorithm: DDPG
DDPG_paras = {"layer_num":4, "layer_dim":250, "max_episode":100, "seed":1234}
control = ControlOpt(save_file=False, method="DDPG", **DDPG_paras)
control.dynamics(
    tspan,
    rho0,
    H0,
    dH,
    Hc,
    decay=decay,
    ctrl_bound=[-2.0, 2.0],
)
# take QFIM as the target function
control.QFIM()
# # take CFIM as the target function
# control.CFIM(M)
# # take HCRB as the target function
# control.HCRB()
