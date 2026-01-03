$PSVersionTable.PSEdition -ne 'Core' | Out-Null

oh-my-posh init pwsh --config "~\.config\ohmyposh\zen.toml" | Invoke-Expression

# terminal icons
Import-Module -Name Terminal-Icons

# PSReadLine configuration
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{
    Command = '#89b4fa'
    Parameter = '#f5c2e7'
    String = '#a6e3a1'
    Operator = '#89dceb'
    Variable = '#fab387'
    Comment = '#6c7086'
}

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# F2 to show prediction list
Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# aliases
Set-Alias -Name c -Value clear
Set-Alias -Name vim -Value nvim
Set-Alias -Name touch -Value New-Item

# Custom functions
function mkcd {
    param($dir)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Location $dir
}

function which {
    param($command)
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

fastfetch
