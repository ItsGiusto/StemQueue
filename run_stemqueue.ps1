# run_stemqueue.ps1
# This script runs the audio separation queue using main.py

# Get the directory where this PowerShell script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Change to the script's directory
Set-Location -Path $ScriptDir

Write-Host "Current working directory: $(Get-Location)"

# --- Optional: Activate a Python virtual environment ---
# If you are using a virtual environment, uncomment and adjust the path below.
# This is highly recommended for managing Python dependencies.
# $VenvPath = Join-Path $ScriptDir "venv/Scripts/Activate.ps1"
# if (Test-Path $VenvPath) {
#     Write-Host "Activating virtual environment..."
#     . $VenvPath
#     Write-Host "Virtual environment activated."
# } else {
#     Write-Host "Virtual environment not found at $VenvPath. Running with system Python."
# }
# -------------------------------------------------------

# Define the path to your Python executable
# It's good practice to use the full path to avoid issues with PATH environment variables
# If using a virtual environment, this would be: (Join-Path $ScriptDir "venv/Scripts/python.exe")
$PythonExe = "python.exe" # Assumes python is in your system PATH, or specify full path like "C:/Python39/python.exe"

# Define the path to your main Python script
$MainScript = "main.py"

# Define the path to your queue JSON file
$QueueFile = "queue_example.json"

Write-Host "Starting audio separation process..."
Write-Host "Python executable: $PythonExe"
Write-Host "Main script: $MainScript"
Write-Host "Queue file: $QueueFile"

# Execute the Python script
try {
    & $PythonExe $MainScript --queue-file $QueueFile
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

# --- Optional: Deactivate virtual environment ---
# If you activated a virtual environment, you might want to deactivate it here.
# This is usually not strictly necessary for scheduled tasks as the session closes.
# if (Test-Path $VenvPath) {
#     Write-Host "Deactivating virtual environment..."
#     deactivate
# }
# --------------------------------------------------

Write-Host "Script finished."
exit $LastExitCode
