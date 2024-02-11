
import os, logging, platform
# import julia_project, julia_project_basic
from julia_project import JuliaProject
from julia_project_basic.basic import run_pkg_commands, run_julia
from pathlib import Path

pkg_path = Path(__file__).parent.parent

def run_pkg_commands_monkey_patch(project_path, commands, julia_exe=None, depot_path=None, clog=False, no_stderr=False):
    if not os.path.isdir(project_path) and not os.path.isfile(project_path):
        raise FileNotFoundError(f"{project_path} does not exist")
    if os.path.isfile(project_path):
        project_path = os.path.dirname(project_path) # julia commands run 250ms faster if we do this. why?
    com = f'import Pkg; Pkg.activate(raw"{project_path}"); ' + commands
    return run_julia(commands=com, julia_exe=julia_exe, depot_path=depot_path, clog=clog, no_stderr=no_stderr)

def _load_julia_utils_monkey_patch(self):
        srcdir = os.path.dirname(os.path.realpath(__file__))
        utilf = os.path.join(srcdir, "utils.jl")
        self.calljulia.seval(f'include(raw"{utilf}")')

## Remove munual monkey patch when fixed

run_pkg_commands = run_pkg_commands_monkey_patch
JuliaProject._load_julia_utils = _load_julia_utils_monkey_patch

project = JuliaProject(
    name="quanestimation",
    package_path=pkg_path,
    version_spec = "^1.9",
    sys_image_dir="sys_image",
    sys_image_file_base=None,
    env_prefix = 'QuanEstimation_',
    logging_level = logging.INFO, # or logging.WA`RN,
    console_logging=False,
    # post_init_hook=_post_init_hook, # Run this after ensure_init
    calljulia = "juliacall"
)