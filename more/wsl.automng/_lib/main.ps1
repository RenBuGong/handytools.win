# main.ps1
. $PSScriptRoot\common.ps1

function Show-MainMenu {
    Write-Host (Get-Message "main_Title") -ForegroundColor Cyan

    Write-Host (Get-Message "main_MenuS")
    Write-Host (Get-Message "main_MenuD")
    Write-Host (Get-Message "main_MenuC")
    Write-Host (Get-Message "main_MenuI")
    Write-Host (Get-Message "main_MenuU")
    Write-Host (Get-Message "main_MenuR")
    Write-Host (Get-Message "main_MenuM")
    Write-Host (Get-Message "main_MenuH")
    Write-Host ""
    Write-Host (Get-Message "main_Menu1")
    Write-Host (Get-Message "main_Menu2")
    Write-Host (Get-Message "main_Menu3")
    Write-Host (Get-Message "main_Menu4")
    Write-Host ""

    Write-Host (Get-Message "main_MenuE")

    $menuPrompt = Get-Message "main_SelectPrompt"
    $choice = Read-Host $menuPrompt
    return $choice.ToUpper()
}

do {
    $mainChoice = Show-MainMenu
    switch ($mainChoice) {
        "S" { & "$PSScriptRoot\show.ps1"; & PauseToMain }
        "D" { & "$PSScriptRoot\download.ps1"; & PauseToMain }
        "C" { & "$PSScriptRoot\show.ps1"; & "$PSScriptRoot\backup.ps1"; & PauseToMain }
        "I" { & "$PSScriptRoot\install.ps1"; & PauseToMain }
        "U" { & "$PSScriptRoot\show.ps1"; & "$PSScriptRoot\adduser.ps1"; & PauseToMain }
        "R" { & "$PSScriptRoot\show.ps1"; & "$PSScriptRoot\remove.ps1"; & PauseToMain }
        "M" { & "$PSScriptRoot\show.ps1"; & "$PSScriptRoot\migrate.ps1"; & PauseToMain }
        "H" { & "$PSScriptRoot\help.ps1"; & PauseToMain }
        "1" { & "$PSScriptRoot\show.ps1"; & "$PSScriptRoot\autostart.ps1"; & PauseToMain }
        "2" { & "$PSScriptRoot\show.ps1"; & "$PSScriptRoot\configure_ssh.ps1"; & PauseToMain }
        "3" { & "$PSScriptRoot\show.ps1"; & "$PSScriptRoot\systemd_toggle.ps1"; & PauseToMain }
        "4" { & "$PSScriptRoot\toggle_network.ps1"; & PauseToMain }

        "E" {
            Write-Host (Get-Message "main_ExitMsg") -ForegroundColor Green
            return
        }
        default {
            Write-Host (Get-Message "main_InvalidChoice") -ForegroundColor Yellow
        }
    }
} while ($true)
