# migrate.ps1
. $PSScriptRoot\common.ps1

function Move-WslInstance {
    # Create the import path by combining the default install directory and the new name
    $importPath = Join-Path $scriptConfig.new_wsl_install_dir $newDistroName

    $distroToMigrate = Read-Host (Get-Message "migrate_EnterDistro" $importPath)
    if ($distroToMigrate -eq 'q') {
        return
    }

    # Check if the instance is running
    $wslStatus = wsl --list --verbose
    $isRunning = $wslStatus -match "$distroToMigrate\s+Running"
    if ($isRunning) {
        Write-Host (Get-Message "migrate_InstRunning" $distroToMigrate) -ForegroundColor Red
        return
    }

    # Get a new name for the imported instance
    $newDistroName = Read-Host (Get-Message "migrate_NewDistroName")
    if ($newDistroName -eq 'q') {
        return
    }


    # Export
    $exportPath = Join-Path $scriptConfig.sys_image_lib_dir ("Backup_{0}{1}.tar" -f $distroToMigrate, (Get-Date -Format 'yyyyMMddHHmmss'))
    Write-Host (Get-Message "migrate_ExportStarting" @($distroToMigrate, $exportPath))
    
    try {
        wsl --export $distroToMigrate $exportPath
        Write-Host (Get-Message "migrate_ExportCompleted" $exportPath) -ForegroundColor Green
    }
    catch {
        Write-Host (Get-Message "migrate_ExportFailed" $_) -ForegroundColor Red
        return
    }

    # Delete
    Write-Host (Get-Message "migrate_Deleting" $distroToMigrate)
    try {
        wsl --unregister $distroToMigrate
        Write-Host (Get-Message "migrate_DeletedOK" $distroToMigrate) -ForegroundColor Green
    }
    catch {
        Write-Host (Get-Message "migrate_DeletedFail" $_) -ForegroundColor Red
        return
    }

    # Import
    Write-Host (Get-Message "migrate_Importing" @($exportPath, $newDistroName, $importPath))
    try {
        wsl --import $newDistroName $importPath $exportPath
        Write-Host (Get-Message "migrate_ImportedOK" $newDistroName) -ForegroundColor Green
    }
    catch {
        Write-Host (Get-Message "migrate_ImportedFail" $_) -ForegroundColor Red
    }
}

Move-WslInstance
