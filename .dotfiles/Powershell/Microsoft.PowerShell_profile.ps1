# Core Check
if ($PSVersionTable.PSEdition -ne 'Core') { return }

# ============================================================================
# Prompt & Theme Configuration
# ============================================================================
$PROMPT_THEME = "ohmyposh"

if ($PROMPT_THEME -eq "starship") {
    $ENV:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"
    Invoke-Expression (&starship init powershell)
} else {
    oh-my-posh init pwsh --config "~\.config\ohmyposh\zen.toml" | Invoke-Expression
}

# ============================================================================
# Modules & Integrations
# ============================================================================
Import-Module PSReadLine
Import-Module Terminal-Icons
Import-Module CompletionPredictor

# Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# PSFzf
if (Get-Module -ListAvailable PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+r' -PSReadlineChordReverseHistory 'Ctrl+r' -TabExpansion
}

# Chocolatey
$ChocoProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocoProfile) { Import-Module $ChocoProfile }

# ============================================================================
# PSReadLine
# ============================================================================
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{
    Command          = '#89b4fa'
    Parameter        = '#f5c2e7'
    String           = '#a6e3a1'
    Operator         = '#89dceb'
    Variable         = '#fab387'
    Comment          = '#6c7086'
    InlinePrediction = '#b4befe'
}

# Key Bindings
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView
Set-PSReadlineKeyHandler -Key Ctrl+UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key Ctrl+DownArrow -Function HistorySearchForward

# ============================================================================
# Aliases & Commands
# ============================================================================
Set-Alias vim nvim
Set-Alias touch New-Item
Set-Alias mv Move-Item
Set-Alias cat Get-Content

function grep { Select-String $args }
function head { Select-Object -First $args }
function tail { Select-Object -Last $args }
function man { Get-Help $args }
function df { Get-PSDrive }

# Override ls/lsa/ll/la with eza if available
Remove-Item Alias:ls -ErrorAction SilentlyContinue
function ls { if (Get-Command eza -ErrorAction SilentlyContinue) { eza --icons @args } else { Get-ChildItem -Force @args } }
function lsa { if (Get-Command eza -ErrorAction SilentlyContinue) { eza -a --icons @args } else { Get-ChildItem -Force @args } }
function ll { if (Get-Command eza -ErrorAction SilentlyContinue) { eza -l --icons @args } else { Get-ChildItem @args | Format-Table -AutoSize } }
function lla { if (Get-Command eza -ErrorAction SilentlyContinue) { eza -la --icons @args } else { Get-ChildItem -Force @args | Format-Table -AutoSize } }

# ============================================================================
# Utility Functions
# ============================================================================
function ~ { Set-Location $HOME }
function mkcd { param($dir) New-Item -ItemType Directory -Force -Path $dir | Out-Null; Set-Location $dir } # Create directory and switch to it
function which { param($cmd) Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path }
function reload { . $PROFILE; Write-Host "Profile reloaded!" -ForegroundColor Green }

function update-all {
    Write-Host "Updating Scoop..." -ForegroundColor Cyan
    scoop update *; scoop update; scoop cleanup *
    Write-Host "Done!" -ForegroundColor Green
}

function fetch {
    param($style = "default")
    $cfg = "$HOME\.config\fastfetch\$style.jsonc"
    if (Test-Path $cfg) { fastfetch --config $cfg } else { fastfetch }
}

function prompt-switch {
    param([string]$theme)
    if ($theme -match "starship|ohmyposh") {
        (Get-Content $PROFILE) -replace '\$PROMPT_THEME = "(ohmyposh|starship)"', "`$PROMPT_THEME = `"$theme`"" | Set-Content $PROFILE
        Write-Host "Switched to $theme. Restart terminal." -ForegroundColor Green
    }
}