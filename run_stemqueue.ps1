# run_stemqueue.ps1
# This script sets up a virtual environment, installs dependencies, and runs the audio separation queue using main.py

# Get the directory where this PowerShell script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Define log file path
$LogFileName = "run_log_$(Get-Date -Format "yyyyMMdd_HHmmss").log"
$LogFilePath = Join-Path $ScriptDir $LogFileName

# Start transcribing all output to the log file
Start-Transcript -Path $LogFilePath -Append -Force

Write-Host "Current working directory: $(Get-Location)"

# Change to the script's directory
Set-Location -Path $ScriptDir

Write-Host "Current working directory (after Set-Location): $(Get-Location)"

# --- Virtual Environment Setup ---
$VenvName = "venv"
$VenvPath = Join-Path $ScriptDir $VenvName
$VenvPythonExe = Join-Path $VenvPath "Scripts/python.exe"
$VenvActivateScript = Join-Path $VenvPath "Scripts/Activate.ps1"

if (-not (Test-Path $VenvPath)) {
    Write-Host "Virtual environment '$VenvName' not found. Creating it..."
    try {
        python -m venv $VenvName
        Write-Host "Virtual environment created successfully."
    } catch {
        Write-Host "Error creating virtual environment: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $VenvActivateScript)) {
    Write-Host "Error: Virtual environment activation script not found at $VenvActivateScript. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host "Activating virtual environment..."
. $VenvActivateScript # Source the activation script
Write-Host "Virtual environment activated."

# Upgrade pip within the virtual environment
Write-Host "Upgrading pip within the virtual environment..."
try {
    & $VenvPythonExe -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error upgrading pip. Exiting." -ForegroundColor Red
        exit 1
    }
    Write-Host "pip upgraded successfully."
} catch {
    Write-Host "An error occurred while upgrading pip: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Install/upgrade audio-separator to the latest available version
Write-Host "Attempting to install/upgrade audio-separator to the latest available version..."
try {
    & $VenvPythonExe -m pip install --upgrade audio-separator
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error installing/upgrading audio-separator. Exiting." -ForegroundColor Red
        exit 1
    }
    Write-Host "audio-separator installed/upgraded successfully."
} catch {
    Write-Host "An error occurred while installing/upgrading audio-separator: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify audio-separator version
Write-Host "Verifying installed audio-separator version..."
try {
    $InstalledVersion = (& $VenvPythonExe -c "import audio_separator; print(audio_separator.__version__)")
    Write-Host "Installed audio-separator version: $InstalledVersion"
    # Removed the version check for 0.45.0 as we are now compatible with 0.44.1
} catch {
    Write-Host "Error verifying audio-separator version: $($_.Exception.Message)" -ForegroundColor Red
}

# List all installed packages
Write-Host "Listing all installed packages (pip freeze):"
& $VenvPythonExe -m pip freeze

# Check if onnxruntime is installed and install if not
Write-Host "Checking for onnxruntime installation..."
try {
    & $VenvPythonExe -c "import onnxruntime" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "onnxruntime not found. Installing..."
        & $VenvPythonExe -m pip install onnxruntime
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error installing onnxruntime. Exiting." -ForegroundColor Red
            exit 1
        }
        Write-Host "onnxruntime installed successfully."
    } else {
        Write-Host "onnxruntime is already installed."
    }
} catch {
    Write-Host "An error occurred while checking/installing onnxruntime: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# --- End Virtual Environment Setup ---

# --- FFmpeg PATH Configuration ---
# IMPORTANT: Update this path if your FFmpeg bin directory is different!
$FFmpegBinPath = "C:\ffmpeg\ffmpeg-master-latest-win64-gpl\bin" # Example path, adjust if needed

if (Test-Path $FFmpegBinPath) {
    Write-Host "Adding FFmpeg to PATH: $FFmpegBinPath"
    $env:Path = "$FFmpegBinPath;$env:Path"
} else {
    Write-Host "WARNING: FFmpeg bin path not found at '$FFmpegBinPath'. Please verify your FFmpeg installation and update the script if necessary." -ForegroundColor Yellow
}
# --- End FFmpeg PATH Configuration ---

# Define the path to your main Python script
$MainScript = "main.py"

# Define the path to your queue JSON file
$QueueFile = "task_queue.json"

Write-Host "Starting audio separation process..."
Write-Host "Python executable: $VenvPythonExe"
Write-Host "Main script: $MainScript"
Write-Host "Queue file: $QueueFile"

# Execute the Python script using the venv's python
try {
    & $VenvPythonExe $MainScript --queue-file $QueueFile
    $LastExitCode = $LASTEXITCODE
    if ($LastExitCode -eq 0) {
        Write-Host "Python script finished successfully."
    } else {
        Write-Host "Python script exited with error code: $LastExitCode" -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred while running the Python script: $($_.Exception.Message)" -ForegroundColor Red
    $LastExitCode = 1 # Indicate an error
}

# Deactivating virtual environment (optional for scheduled tasks as session closes)
# Write-Host "Deactivating virtual environment..."
# deactivate

Write-Host "Script finished."
sleep 300
exit $LastExitCode
Stop-Transcript
