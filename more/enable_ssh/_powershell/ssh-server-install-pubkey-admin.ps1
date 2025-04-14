# Check if a parameter was passed
if ($args.Count -eq 0) {
    Write-Output "Please provide the path to the id_rsa.pub file as the first argument."
    exit
}

# Use the first parameter as the id_rsa.pub file path
$idRsaPubPath = $args[0]

# Verify the file exists
if (-not (Test-Path -Path $idRsaPubPath)) {
    Write-Output "The provided id_rsa.pub file path is invalid or the file does not exist: $idRsaPubPath"
    exit
}

# Create the target directory if it does not exist
$targetDir = "C:\ProgramData\ssh\"
if (-not (Test-Path -Path $targetDir)) {
    mkdir $targetDir
}

# Copy the file to the target location
$targetFile = Join-Path -Path $targetDir -ChildPath "administrators_authorized_keys"
Copy-Item -Path $idRsaPubPath -Destination $targetFile -Force

# Set file permissions
icacls.exe $targetFile /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
Pause
