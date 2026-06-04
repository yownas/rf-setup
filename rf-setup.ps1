# RuinedFooocus setup script for poor Windows users

function Get-MenuSelection {
    param(
        [String[]]$MenuItems = @("Exit"),
        [String]$MenuPrompt = "Select an option"
    )
    $cursorPosition = $host.UI.RawUI.CursorPosition
    $pos = 0
    $key = $null

    function Write-Menu {
        param ([int]$selectedItemIndex)
        $Host.UI.RawUI.CursorPosition = $cursorPosition
        Write-Host $MenuPrompt -ForegroundColor Green
        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            $line = "    $($i+1) $($MenuItems[$i])"
            if ($selectedItemIndex -eq $i) {
                Write-Host $line -ForegroundColor Blue -BackgroundColor Gray
            } else {
                Write-Host $line
            }
        }
    }

    Write-Menu -selectedItemIndex $pos
    while ($key -ne 13) {
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $key = $press.virtualkeycode
        if ($key -eq 38) { $pos-- }
        if ($key -eq 40) { $pos++ }
        if ($pos -lt 0) { $pos = 0 }
        if ($pos -eq $MenuItems.Count) { $pos = $MenuItems.Count - 1 }
        Write-Menu -selectedItemIndex $pos
    }
    return "$($pos+1)"
}

# Status bar
function Status-Bar {
    $got_python = Test-Path -Path "python_embeded"
    $got_rf = Test-Path -Path "RuinedFooocus"
    $chars = [ordered]@{'True'='Installed';'False'='Not found'}
    Write-Host "Python: $($chars["$got_python"]) | RuinedFooocus: $($chars["$got_rf"])"
}

# Loop Python
function Install-Python {
    param(
        [String]$Version = "3.13.13"
    )
    Write-Host "Please wait, downloading python $Version and some required modules."

    $Url = "https://www.python.org/ftp/python/$Version/python-$Version-embed-amd64.zip"
    $Result = "python_embeded"
    $Dl = "dl"

    if (Test-Path $Result) {
        Write-Host "$Result already exists"
        return
    }

    if (-not (Test-Path $Dl)) {
        New-Item -ItemType Directory -Path $Dl | Out-Null
    }

    New-Item -ItemType Directory -Path $Result | Out-Null

    # Download embedded Python
    Invoke-WebRequest -Uri $Url -OutFile "$Dl\embed.zip"

    # Extract archive
    Expand-Archive -Path "$Dl\embed.zip" -DestinationPath $Result

    # Rename *_pth -> *.pth
    Get-ChildItem "$Result\python*._pth" | ForEach-Object {
        $NewName = $_.Name -replace '_pth$', 'pth'
        Rename-Item -Path $_.FullName -NewName $NewName
    }

    # Enable site-packages
    $PthFile = Get-ChildItem "$Result\python*.pth" | Select-Object -First 1
    Add-Content -Path $PthFile.FullName -Value "import site"

    # Download get-pip.py
    Invoke-WebRequest `
        -Uri "https://bootstrap.pypa.io/get-pip.py" `
        -OutFile "$Result\get-pip.py"

    # Install pip
    & "$Result\python.exe" "$Result\get-pip.py"

    # Install packages
    & "$Result\Scripts\pip.exe" install `
        wheel `
        packaging `
        pygit2 `
        setuptools==80.9.0 `
        cffi==2.0.0

    Write-Host "Done..."
}
function Loop-Python {
    do {
        Clear
        Status-Bar
        $input = Get-MenuSelection @("3.10.20", "3.13.13 (Recommended)", "Back") "Select python version"
        switch ($input) {
            '1' { Install-Python "3.10.20"; Pause }
            '2' { Install-Python "3.13.13"; Pause }
            '3' { return }
        }
    } until ($input -eq "$MenuItems.Count")
}

# Install RuinedFooocus
function Get-RF {
    param(
        [String]$Branch = "main"
    )
    $Repo = "https://github.com/runew0lf/RuinedFooocus/"
    Write-Host "Please wait. Cloning branch $Branch from $Repo"
    python_embeded\python.exe -c "import pygit2;pygit2.clone_repository('$Repo', 'RuinedFooocus', checkout_branch='$Branch')"
    Write-Host "Done..."
    Pause
}
function Loop-RF {
    if (-not (Test-Path -Path "python_embeded")) {
        Write-Host "Sorry, you need to install python first."
        Pause
        return
    }
    if (Test-Path -Path "RuinedFooocus") {
        Write-Host "Sorry, you already have a RuinedFooocus folder."
        Pause
        return
    }
    do {
        Clear
        Status-Bar
        $input = Get-MenuSelection @("main (recommended)", "development", "Back") "Get RuinedFooocus"
        switch ($input) {
            '1' { Get-RF "main" }
            '2' { Get-RF "development" }
            '3' { return }
        }
    } until ($input -eq "$MenuItems.Count")
}

# Select torch
function Torch-Reinstall {
    param(
        [String]$IndexUrl = ""
    )
    Write-Host "Removing old torch install"
    python_embeded\Scripts\pip.exe uninstall -y torch torchvision torchaudio
    Write-Host "Installing new torch from $IndexUrl (This might take a while)"
    python_embeded\Scripts\pip.exe install --pre torch torchvision torchaudio --index-url $IndexUrl
    Write-Host "Lock Torch version"
    New-Item -ItemType File -Path "RuinedFooocus\freezetorch" -Force | Out-Null
    Write-Host "Done..."
}
function Loop-Torch {
    if (-not (Test-Path -Path "python_embeded")) {
        Write-Host "Sorry, you need to install python first."
        Pause
        return
    }
    if (-not (Test-Path -Path "RuinedFooocus")) {
        Write-Host "Sorry, you need to get RuinedFooocus first."
        Pause
        return
    }
    do {
        Clear
        Status-Bar
        $input = Get-MenuSelection @(
            "Auto (recommended) (Will remove current Torch)",
            "CUDA 12.4",
            "CUDA 12.8",
            "CUDA 13.0",
            "CUDA 13.2 (nightly)",
            "RDNA 3 (RX 7000)",
            "RDNA 3.5 (Strix halo/Ryzen AI Max+ 365)",
            "RDNA 4 (RX 9000)",
            "cpu",
            "freeze current torch version",
            "unfreeze (RF might update Torch automatically)",
            "Back"
        ) "Select Torch version"
        switch ($input) {
            '1' {
                Write-Host "Removing old torch install"
                python_embeded\Scripts\pip.exe uninstall -y torch torchvision torchaudio
                if (Test-Path -Path "RuinedFooocus\freezetorch") {
                    Remove-Item -Path "RuinedFooocus\freezetorch"
                }
                Write-Host "Torch unfrozen"
                Pause
            }
            '2' { Torch-Reinstall "https://download.pytorch.org/whl/cu124/" }
            '3' { Torch-Reinstall "https://download.pytorch.org/whl/cu128/" }
            '4' { Torch-Reinstall "https://download.pytorch.org/whl/cu130/" }
            '5' { Torch-Reinstall "https://download.pytorch.org/whl/nightly/cu132/" }
            '6' { Torch-Reinstall "https://rocm.nightlies.amd.com/v2/gfx110X-all/" }
            '7' { Torch-Reinstall "https://rocm.nightlies.amd.com/v2/gfx1151/" }
            '8' { Torch-Reinstall "https://rocm.nightlies.amd.com/v2/gfx120x-all/" }
            '9' { Torch-Reinstall "https://download.pytorch.org/whl/cpu" }
            '10' {
                New-Item -ItemType File -Path "RuinedFooocus\freezetorch" -Force | Out-Null
                Write-Host "Torch frozen"
                Pause
            }
            '11' {
                if (Test-Path -Path "RuinedFooocus\freezetorch") {
                    Remove-Item -Path "RuinedFooocus\freezetorch"
                }
                Write-Host "Torch unfrozen"
                Pause
            }
            '12' { return }
        }
    } until ($input -eq "$MenuItems.Count")
}

# Create run.bat script
function Create-Run-Bat {
    $runbat = "run.bat"
    if (Test-Path -Path "$runbat") {
        Write-Host "Sorry, you already have a $runbat file."
        Pause
        return
    }
    $batdata = @"
.\python_embeded\python.exe -s RuinedFooocus\entry_with_update.py
pause
"@
    $batdata | Out-File -FilePath "$runbat"
    Write-Host "Done..."
    pause
}

# Misc. Operations
function Loop-Ops {
    if (-not (Test-Path -Path "python_embeded")) {
        Write-Host "Sorry, you need to install python first."
        Pause
        return
    }
    if (-not (Test-Path -Path "RuinedFooocus")) {
        Write-Host "Sorry, you need to get RuinedFooocus first."
        Pause
        return
    }
    do {
        Clear
        Status-Bar
        $input = Get-MenuSelection @(
            "Trigger reinstall of all python modules next start",
            "Trigger reinstall of Torch next start (will set selected version to Auto)",
            "Back"
        ) "Operations"
        switch ($input) {
            '1' {
                New-Item -ItemType File -Path "RuinedFooocus\reinstall" -Force | Out-Null
                Write-Host "Reinstall of python modules queued"
                Pause
            }
            '2' {
                Write-Host "Removing old torch install"
                python_embeded\Scripts\pip.exe uninstall -y torch torchvision torchaudio
                if (Test-Path -Path "RuinedFooocus\freezetorch") {
                    Remove-Item -Path "RuinedFooocus\freezetorch"
                }
                New-Item -ItemType File -Path "RuinedFooocus\reinstalltorch" -Force | Out-Null
                Write-Host "Torch unfrozen and reinstall queued"
                Pause
            }
            '3' { return }
        }
    } until ($input -eq "$MenuItems.Count")
}

# Start RuinedFooocus
function Start-RF {
    if (-not (Test-Path -Path "python_embeded")) {
        Write-Host "Sorry, you need to install python first."
        Pause
        return
    }
    if (-not (Test-Path -Path "RuinedFooocus")) {
        Write-Host "Sorry, you need to get RuinedFooocus first."
        Pause
        return
    }
    Write-Host "Starting RuinedFooocus..."
    .\python_embeded\python.exe -s RuinedFooocus\entry_with_update.py
    pause
}

# Main loop
do {
    Clear
    Status-Bar
    $input = Get-MenuSelection @(
        "Select python",
        "Install RuinedFooocus",
        "Select Torch version",
        "Write run.bat start script",
        "Other operations",
        "Start RuinedFooocus",
        "Exit"
    )
    switch ($input) {
        '1' { Loop-Python }
        '2' { Loop-RF }
        '3' { Loop-Torch }
        '4' { Create-Run-Bat }
        '5' { Loop-Ops }
        '6' { Start-RF }
        '7' { return }
    }
} until ($input -eq "$MenuItems.Count")
