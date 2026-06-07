# Setup script for [RuinedFooocus](https://github.com/runew0lf/RuinedFooocus/)

## Windows

### rf-setup.ps1

#### Setup steps

1. Download [rf-setup.ps1](https://raw.githubusercontent.com/yownas/rf-setup/refs/heads/main/rf-setup.ps1) and save it in an empty new folder where you want to install RuinedFooocus.
2. Run the script.
3. Select python version.
4. Install RuinedFoocus by selecting branch (you most likely want the "main" branch)
5. Optional: Select Torch version. RuinedFooocus will try to automatically find a good version that fits your GPU, but AMD users might need to force a specific version.
6. Optional (but recommended): Create a run.bat script that will start RuinedFooocus

Under `Select Torch version` you can also freeze/unfreeze the currently installed version. Startup will be a little bit faster since RF will skip the Torch-check.

#### If it doesn't work

* You might need to install [Visual C++ Redistributable for Visual Studio 2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145) for RuinedFoocus to run properly.
* If the script doesn't start you might need to open up a PowerShell and run:<br>`Set-ExecutionPolicy Unrestricted -Scope CurrentUser`<br>to allow scripts. More information [here](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.6).

## Linux

### rf-setup.sh

* Almost the same as above...

#### If it doesn't work

* The script requires that you have git and wget installed.
