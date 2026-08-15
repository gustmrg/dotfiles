[CmdletBinding()]
param(
    [switch]$Yes
)

$ErrorActionPreference = "Stop"
$manifest = Join-Path $PSScriptRoot "sources.txt"

if (-not $Yes) {
    $answer = Read-Host "Install Fira Code, IBM Plex Mono, and Source Code Pro for this user? [y/N]"
    if ($answer -notmatch '^(y|yes)$') {
        Write-Host "Font installation cancelled."
        exit 0
    }
}

if (-not (Test-Path $manifest)) {
    throw "Font manifest not found: $manifest"
}

$fontDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$registryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("dotfiles-fonts-" + [guid]::NewGuid())

New-Item -ItemType Directory -Force -Path $fontDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $temporaryDirectory | Out-Null
New-Item -Path $registryPath -Force | Out-Null

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class DotfilesFontInstaller {
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    public static extern int AddFontResource(string fileName);
}
"@

try {
    Get-Content $manifest | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
            return
        }

        $parts = $line -split '\|', 2
        $family = $parts[0]
        $url = $parts[1]
        $archive = Join-Path $temporaryDirectory (($family -replace ' ', '-') + ".zip")
        $extractDirectory = Join-Path $temporaryDirectory ($family -replace ' ', '-')

        Write-Host "Downloading $family..."
        Invoke-WebRequest -Uri $url -OutFile $archive
        Expand-Archive -Path $archive -DestinationPath $extractDirectory -Force

        $fontFiles = @(Get-ChildItem -Path $extractDirectory -Recurse -File |
            Where-Object { $_.Extension -in @('.ttf', '.otf') }
        )
        if ($fontFiles.Count -eq 0) {
            throw "No TTF or OTF files found in the $family download."
        }

        $fontFiles | ForEach-Object {
            $destination = Join-Path $fontDirectory $_.Name
            Copy-Item -Path $_.FullName -Destination $destination -Force
            [DotfilesFontInstaller]::AddFontResource($destination) | Out-Null
            New-ItemProperty -Path $registryPath -Name $_.BaseName -Value $destination -PropertyType String -Force | Out-Null
        }
    }
}
finally {
    Remove-Item -Path $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Installed fonts into $fontDirectory"
Write-Host "Restart applications that were open before the installation."
