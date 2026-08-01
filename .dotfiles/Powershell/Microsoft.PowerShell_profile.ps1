# Core Check
if ($PSVersionTable.PSEdition -ne 'Core') { return }

# Uncomment to debug slow startups: prints load time at the end of the profile
# $script:ProfileLoadStart = Get-Date

# Prompt & Theme Configuration
$PROMPT_THEME = "ohmyposh"
$IsVSCode = $env:TERM_PROGRAM -eq "vscode"
$PromptCacheDir = "$HOME\.cache"
$PromptCacheFile = "$PromptCacheDir\prompt-init.ps1"
$OhMyPoshConfig = "$HOME\.config\ohmyposh\catppuccin.json"
$StarshipConfig = "$HOME\.config\starship\starship.toml"

function Update-PromptCache {
    param([string]$Theme = $PROMPT_THEME)
    if (-not (Test-Path $PromptCacheDir)) {
        New-Item -ItemType Directory -Path $PromptCacheDir -Force | Out-Null
    }
    if ($Theme -eq "starship" -and (Get-Command starship -ErrorAction SilentlyContinue)) {
        $ENV:STARSHIP_CONFIG = $StarshipConfig
        starship init powershell > $PromptCacheFile
    }
    elseif (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        oh-my-posh init pwsh --config $OhMyPoshConfig > $PromptCacheFile
    }
}

if (-not $IsVSCode) {
    $ConfigPath = if ($PROMPT_THEME -eq "starship") { $StarshipConfig } else { $OhMyPoshConfig }

    $NeedsRefresh = (-not (Test-Path $PromptCacheFile)) -or
        ((Test-Path $ConfigPath) -and (Get-Item $ConfigPath).LastWriteTime -gt (Get-Item $PromptCacheFile).LastWriteTime)

    if ($NeedsRefresh) {
        Update-PromptCache -Theme $PROMPT_THEME
    }
    elseif ($PROMPT_THEME -eq "starship") {
        $ENV:STARSHIP_CONFIG = $StarshipConfig
    }

    if (Test-Path $PromptCacheFile) {
        . $PromptCacheFile
    }
}

# Modules & Integrations
foreach ($mod in 'PSReadLine', 'CompletionPredictor') {
    if (Get-Module -ListAvailable -Name $mod) {
        Import-Module $mod -ErrorAction SilentlyContinue
    }
}

$script:HasEza = $null -ne (Get-Command eza -ErrorAction SilentlyContinue)

# PSFzf + zoxide (lazy-load after the prompt appears — both shell out /
# spawn a process, so deferring them keeps the prompt from waiting on them)
function Initialize-PSFzf {
    if (-not (Get-Module PSFzf) -and (Get-Module -ListAvailable PSFzf)) {
        Import-Module PSFzf

        Set-PsFzfOption `
            -PSReadlineChordProvider 'Ctrl+r' `
            -PSReadlineChordReverseHistory 'Ctrl+r' `
            -TabExpansion
    }
}

function Initialize-Zoxide {
    if (-not $script:ZoxideLoaded -and (Get-Command zoxide -ErrorAction SilentlyContinue)) {
        Invoke-Expression (& { zoxide init powershell | Out-String })
        $script:ZoxideLoaded = $true
    }
}

Register-EngineEvent PowerShell.OnIdle -Action {
    Initialize-PSFzf
    Initialize-Zoxide
    Unregister-Event -SubscriptionId $event.SubscriptionId
} | Out-Null

# PSReadLine
if (Get-Module PSReadLine) {
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
}

# Aliases & Commands
Set-Alias vim nvim
Set-Alias mv Move-Item
Set-Alias cat Get-Content
Set-Alias time Measure-Command

function grep {
    if ($input) {
        $input | Select-String @args
    } else {
        Select-String @args
    }
}

function head {
    param([int]$Count = 10)
    $input | Select-Object -First $Count
}

function tail {
    param([int]$Count = 10)
    $input | Select-Object -Last $Count
}

function man { Get-Help @args }
function df { Get-PSDrive }

function touch {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path $Path) {
        (Get-Item $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path | Out-Null
    }
}

# Override ls/lsa/ll/la with eza if available
Remove-Item Alias:ls -ErrorAction SilentlyContinue

function _Invoke-DirListing {
    param(
        [string[]]$EzaArgs,
        [switch]$FallbackTable,
        [object[]]$UserArgs
    )
    if ($script:HasEza) {
        eza @EzaArgs @UserArgs
    } elseif ($FallbackTable) {
        Get-ChildItem -Force @UserArgs | Format-Table -AutoSize
    } else {
        Get-ChildItem -Force @UserArgs
    }
}

function ls  { _Invoke-DirListing -EzaArgs '--icons' -UserArgs $args }
function lsa { _Invoke-DirListing -EzaArgs '-a', '--icons' -UserArgs $args }
function ll  { _Invoke-DirListing -EzaArgs '-l', '--icons' -FallbackTable -UserArgs $args }
function lla { _Invoke-DirListing -EzaArgs '-la', '--icons' -FallbackTable -UserArgs $args }

# Utility Functions
function ~ { Set-Location $HOME }
function mkcd { param($dir) New-Item -ItemType Directory -Force -Path $dir | Out-Null; Set-Location $dir } # Create directory and switch to it
function o {
    explorer .
}

# Resolves aliases and functions too, not just external binaries
function which {
    param([Parameter(Mandatory)][string]$cmd)
    $found = Get-Command $cmd -All -ErrorAction SilentlyContinue
    if (-not $found) {
        Write-Host "which: no '$cmd' found" -ForegroundColor Red
        return
    }
    foreach ($c in $found) {
        switch ($c.CommandType) {
            'Alias'       { Write-Host "$($c.Name): alias -> $($c.Definition)" -ForegroundColor Yellow }
            'Function'    {
                $loc = if ($c.ScriptBlock.File) { $c.ScriptBlock.File } else { "profile/session" }
                Write-Host "$($c.Name): function ($loc)" -ForegroundColor Cyan
            }
            'Cmdlet'      { Write-Host "$($c.Name): cmdlet [$($c.ModuleName)]" -ForegroundColor Magenta }
            'Application' { Write-Host $c.Source -ForegroundColor Green }
            default       { Write-Host "$($c.Name): $($c.CommandType)" }
        }
    }
}

function reload { . $PROFILE; Write-Host "Profile reloaded!" -ForegroundColor Green }

function update-all {
    Write-Host ""
    Write-Host "Updating Scoop packages..." -ForegroundColor Cyan
    scoop update; scoop update *; scoop cleanup *; scoop cache rm *
    Write-Host ""
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Updating winget packages..." -ForegroundColor Cyan
        winget upgrade --all --include-unknown --silent --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "winget not found, skipping winget updates." -ForegroundColor Yellow
    }

    Write-Host "Done!" -ForegroundColor Green
}

function clean-all {
    Write-Host "Cleaning Scoop..." -ForegroundColor Cyan
    scoop cleanup *
    scoop cache rm *
    Write-Host "Done!" -ForegroundColor Green
    Write-Host "Cleaning temp files..." -ForegroundColor Cyan
    Remove-Item -Recurse -Force "$env:TEMP\*" 2>$null
    Remove-Item -Recurse -Force "C:\Windows\TEMP\*" 2>$null
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
        Remove-Item $PromptCacheFile -ErrorAction SilentlyContinue
        Write-Host "Switched to $theme. Restart terminal." -ForegroundColor Green
    }
}

if ($script:ProfileLoadStart) {
    $elapsed = ((Get-Date) - $script:ProfileLoadStart).TotalMilliseconds
    Write-Host "Profile loaded in $([math]::Round($elapsed))ms" -ForegroundColor DarkGray
}
