#Requires -Version 5.1
<#
.SYNOPSIS
  Install and configure STM32 command-line dev tools for led_blink (Windows).

.DESCRIPTION
  - Installs GNU Arm Embedded Toolchain, xPack OpenOCD, and Make via winget (if missing)
  - Adds tool bin directories to the user PATH
  - Sets OPENOCD_SCRIPTS for OpenOCD config file resolution

  After running, restart Cursor/terminals so PATH changes take effect.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-FirstExistingPath {
    param([string[]]$Candidates)
    foreach ($p in $Candidates) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }
    return $null
}

function Find-OpenOcdScriptsDir {
    $root = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path -LiteralPath $root) {
        $matches = Get-ChildItem -LiteralPath $root -Directory -Filter 'xpack-dev-tools.openocd-xpack_*' -ErrorAction SilentlyContinue
        foreach ($dir in $matches) {
            $scripts = Get-ChildItem -LiteralPath $dir.FullName -Directory -Filter 'xpack-openocd-*' -ErrorAction SilentlyContinue |
                ForEach-Object { Join-Path $_.FullName 'openocd\scripts' } |
                Where-Object { Test-Path -LiteralPath $_ }
            if ($scripts) { return @($scripts)[0] }
        }
    }
    return $null
}

function Add-UserPathEntry {
    param([string]$Entry)
    if (-not $Entry) { return }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @()
    if ($userPath) { $parts = $userPath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' } }
    $normalized = $Entry.TrimEnd('\')
    if ($parts -contains $normalized) { return }
    $parts += $normalized
    [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
    Write-Host "Added to user PATH: $normalized"
}

Write-Host '=== led_blink: development tools setup ==='

$winget = Get-Command winget -ErrorAction SilentlyContinue
if ($winget) {
    Write-Host 'Ensuring winget packages...'
    & winget install `
        Arm.GnuArmEmbeddedToolchain `
        xpack-dev-tools.openocd-xpack `
        ezwinports.make `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity `
        2>&1 | Out-Host
} else {
    Write-Warning 'winget not found; install tools manually or install App Installer from Microsoft Store.'
}

$armGccBin = Find-FirstExistingPath @(
    'C:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi\14.2 rel1\bin',
    'C:\Program Files\Arm GNU Toolchain arm-none-eabi\14.2 rel1\bin'
)
if (-not $armGccBin) {
    $armRoot = Find-FirstExistingPath @(
        'C:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi',
        'C:\Program Files\Arm GNU Toolchain arm-none-eabi'
    )
    if ($armRoot) {
        $ver = Get-ChildItem -LiteralPath $armRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($ver) { $armGccBin = Join-Path $ver.FullName 'bin' }
    }
}

$makeBin = Find-FirstExistingPath @(
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\ezwinports.make_Microsoft.Winget.Source_8wekyb3d8bbwe\bin')
)
if (-not $makeBin) {
    $makePkg = Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Directory -Filter 'ezwinports.make_*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($makePkg) { $makeBin = Join-Path $makePkg.FullName 'bin' }
}

$openocdBin = Find-FirstExistingPath @(
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin')
)
if (-not $openocdBin) {
    $ocPkg = Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Directory -Filter 'xpack-dev-tools.openocd-xpack_*' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ocPkg) {
        $ocVer = Get-ChildItem -LiteralPath $ocPkg.FullName -Directory -Filter 'xpack-openocd-*' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($ocVer) { $openocdBin = Join-Path $ocVer.FullName 'bin' }
    }
}

$openocdScripts = Find-OpenOcdScriptsDir

foreach ($bin in @($armGccBin, $openocdBin, $makeBin)) {
    Add-UserPathEntry -Entry $bin
}

if ($openocdScripts) {
    [Environment]::SetEnvironmentVariable('OPENOCD_SCRIPTS', $openocdScripts, 'User')
    Write-Host ('Set OPENOCD_SCRIPTS=' + $openocdScripts)
} else {
    Write-Warning 'Could not locate OpenOCD scripts directory; flash/debug may fail until OPENOCD_SCRIPTS is set.'
}

Write-Host ''
Write-Host 'Verify in a NEW terminal:'
Write-Host '  arm-none-eabi-gcc --version'
Write-Host '  make --version'
Write-Host '  openocd --version'
Write-Host ''
Write-Host 'Build:  make -C D:\projects\led_blink'
Write-Host 'Flash:  openocd -f openocd.cfg -c "program build/led_blink.elf verify reset exit"'

if (-not $armGccBin) { Write-Warning 'arm-none-eabi-gcc bin directory not found.' }
if (-not $makeBin) { Write-Warning 'make bin directory not found.' }
if (-not $openocdBin) { Write-Warning 'openocd bin directory not found.' }

Write-Host '=== Done ==='
