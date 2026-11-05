# ==============================================================================
# T-Zero PC-Fixer & Codebase Doctor Universal 1-Click Installer (Windows PowerShell)
# ==============================================================================
# Installs pc-fixer CLI and configures MCP for Claude Desktop, Cursor, and Windsurf.
# 100% Free & Local Offline | Zero Cloud Cost ($0.00)
#
# Usage:
#   irm https://raw.githubusercontent.com/toprakahmetaydogmus/tzero-pc-fixer/main/install.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "🩺 Initializing T-Zero PC-Fixer & Codebase Doctor Installer..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray

# 1. Check Python
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    $pythonCmd = Get-Command py -ErrorAction SilentlyContinue
}

if (-not $pythonCmd) {
    Write-Host "[ERROR] Python is required but not found in system PATH." -ForegroundColor Red
    Write-Host "Please install Python from https://www.python.org/downloads/ and check 'Add python.exe to PATH'."
    exit 1
}

$pyVer = & $pythonCmd.Source -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
Write-Host "✔ Found Python: v$pyVer" -ForegroundColor Green

# 2. Target installation directory
$installDir = Join-Path $env:LOCALAPPDATA "Programs\tzero-pc-fixer"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

$fixerUrl = "https://raw.githubusercontent.com/toprakahmetaydogmus/tzero-pc-fixer/main/tzero_pc_fixer.py"
$mcpUrl   = "https://raw.githubusercontent.com/toprakahmetaydogmus/tzero-pc-fixer/main/pc_fixer_mcp.py"

Write-Host "📥 Downloading standalone monolithic executable..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $fixerUrl -OutFile (Join-Path $installDir "tzero_pc_fixer.py")
Invoke-WebRequest -Uri $mcpUrl -OutFile (Join-Path $installDir "pc_fixer_mcp.py")

# Create CMD wrappers for cmd.exe and PowerShell execution
$pcFixerCmd = @"
@echo off
"$($pythonCmd.Source)" "%~dp0tzero_pc_fixer.py" %*
"@
Set-Content -Path (Join-Path $installDir "pc-fixer.cmd") -Value $pcFixerCmd -Encoding ASCII
Set-Content -Path (Join-Path $installDir "tzero-doctor.cmd") -Value $pcFixerCmd -Encoding ASCII

$pcFixerMcpCmd = @"
@echo off
"$($pythonCmd.Source)" "%~dp0pc_fixer_mcp.py" %*
"@
Set-Content -Path (Join-Path $installDir "pc-fixer-mcp.cmd") -Value $pcFixerMcpCmd -Encoding ASCII

# 3. Add to User PATH if missing
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
    $env:Path += ";$installDir"
    Write-Host "✔ Added $installDir to User PATH" -ForegroundColor Green
}

# 4. Inject into Claude Desktop MCP config if installed
$claudeConfig = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"
if (Test-Path $claudeConfig) {
    try {
        $json = Get-Content $claudeConfig -Raw | ConvertFrom-Json
        if (-not $json.mcpServers) {
            $json | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
        }
        $mcpExe = (Join-Path $installDir "pc-fixer-mcp.cmd")
        $json.mcpServers | Add-Member -MemberType NoteProperty -Name "pc-fixer" -Value ([PSCustomObject]@{
            command = $mcpExe
        }) -Force
        $json | ConvertTo-Json -Depth 10 | Set-Content $claudeConfig -Encoding UTF8
        Write-Host "✔ Injected pc-fixer into Claude Desktop MCP configuration!" -ForegroundColor Green
    } catch {
        Write-Host "Notice: Claude configuration auto-update skipped: $_" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "✨ T-Zero PC-Fixer installed successfully!" -ForegroundColor Green
Write-Host "Run: pc-fixer --help to get started." -ForegroundColor Yellow
Write-Host "MCP Server available at: pc-fixer-mcp" -ForegroundColor Yellow
Write-Host ""

