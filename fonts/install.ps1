[CmdletBinding()]
param(
    [switch]$Yes,
    [string]$Only
)

$ErrorActionPreference = "Stop"
$manifest = Join-Path $PSScriptRoot "sources.txt"

if (-not (Test-Path $manifest)) {
    throw "Font manifest not found: $manifest"
}

$entries = @()
Get-Content $manifest | ForEach-Object {
    $line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        return
    }

    $parts = $line -split '\|', 3
    $entries += [pscustomobject]@{
        Family = $parts[0].Trim()
        Url    = $parts[1].Trim()
        Filter = $parts[2]
    }
}

if ($entries.Count -eq 0) {
    throw "No font entries found in the manifest: $manifest"
}

# Family selector. Skipped when -Yes or -Only was given, both of which
# represent explicit consent.
if (-not $Yes) {
    if ($Only) {
        foreach ($name in ($Only -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
            if ($entries.Family -notcontains $name) {
                throw "Requested font not found in the manifest: $name"
            }
        }
    }
    else {
        Write-Host "Available fonts:"
        for ($i = 0; $i -lt $entries.Count; $i++) {
            Write-Host ("  {0}) {1}" -f ($i + 1), $entries[$i].Family)
        }
        Write-Host ""
        $answer = Read-Host "Choose numbers or names separated by commas/spaces, or 'all' [all]"
        if ([string]::IsNullOrWhiteSpace($answer)) {
            $answer = "all"
        }

        $picked = @()
        foreach ($item in ($answer -split '[,\s]+' | Where-Object { $_ })) {
            if ($item -ieq "all") {
                $picked = @()
                break
            }
            elseif ($item -match '^\d+$') {
                $index = [int]$item
                if ($index -lt 1 -or $index -gt $entries.Count) {
                    throw "Unknown selection: $item"
                }
                $picked += $entries[$index - 1].Family
            }
            else {
                $match = $entries | Where-Object { $_.Family -ieq $item } | Select-Object -First 1
                if (-not $match) {
                    throw "Unknown font: $item"
                }
                $picked += $match.Family
            }
        }
        if ($picked.Count -gt 0) {
            $Only = ($picked | Select-Object -Unique) -join ','
        }
        else {
            $Only = ""
        }
    }
}

if ($Only) {
    $requested = $Only -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $entries = $entries | Where-Object { $requested -icontains $_.Family }
    if ($entries.Count -eq 0) {
        throw "None of the requested fonts were found in the manifest."
    }
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
    $entries | ForEach-Object {
        $family = $_.Family
        $url = $_.Url
        $filter = $_.Filter
        $archive = Join-Path $temporaryDirectory (($family -replace ' ', '-') + ".zip")
        $extractDirectory = Join-Path $temporaryDirectory ($family -replace ' ', '-')

        Write-Host "Downloading $family..."
        Invoke-WebRequest -Uri $url -OutFile $archive
        Expand-Archive -Path $archive -DestinationPath $extractDirectory -Force

        $fontFiles = @(Get-ChildItem -Path $extractDirectory -Recurse -File |
            Where-Object { $_.Extension -in @('.ttf', '.otf') } |
            Where-Object { [string]::IsNullOrEmpty($filter) -or $_.FullName -like "*$filter*" }
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
