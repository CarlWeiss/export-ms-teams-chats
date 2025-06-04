<#
Overview: Searches for files in a directory that match a regex pattern and copies them to an output directory.
         Also copies related assets (like images, scripts) referenced in HTML files.
         This is useful for searching the exported chat files for specific content and ensuring all related assets are included.
Author: Carl Weiss
#>

[cmdletbinding()]
Param([bool]$verbose)
$VerbosePreference = if ($verbose) { 'Continue' } else { 'SilentlyContinue' }

# Copy Related assets to output directory.
# Example usage:
# Copy-RelatedAssets -HtmlFilePath "C:\input\example.html" -exportFolder "C:\input" -outputDirectory "C:\output"  
function Copy-RelatedAssets {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HtmlFilePath,
        [Parameter(Mandatory = $true)]
        [string]$exportFolder,
        [Parameter(Mandatory = $true)]
        [string]$outputDirectory
    )

    Write-Host "Scanning $HtmlFilePath for related assets"
    # Read the HTML content
    $content = [System.IO.File]::ReadAllText($HtmlFilePath)

    # Regex to find src/href links that contain the related "assets/"
    $srcPattern = '(?:src|href)\s*=\s*["'']((?:\.?/)?assets/[^"'']+)["'']'
    $srcMatches = [regex]::Matches($content, $srcPattern)

    # Get a unique list of asset paths
    $uniqueAssetPaths = $srcMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    foreach ($relativeAssetPath in $uniqueAssetPaths) {
        $assetCount++
        Write-Host "Copying data: $relativeAssetPath"
        $sourceAssetPath = Join-Path $exportFolder $relativeAssetPath
        $targetAssetPath = Join-Path $outputDirectory $relativeAssetPath

        # Ensure the target directory exists
        $targetAssetDir = Split-Path $targetAssetPath -Parent
        if (-not (Test-Path $targetAssetDir)) {
            New-Item -ItemType Directory -Path $targetAssetDir -Force | Out-Null
        }

        # Copy the asset if it exists
        if (Test-Path $sourceAssetPath) {
            Copy-Item -Path $sourceAssetPath -Destination $targetAssetPath -Force
        }
    }
}


# Find and copy chat streams with content matching the regex expression
# Example usage:
# Copy-MatchingFiles -exportFolder "C:\input" -outputDirectory "C:\output" regexPattern ".*\.html$"
        

function Copy-MatchingFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$exportFolder,
        [Parameter(Mandatory = $true)]
        [string]$outputDirectory,
        [Parameter(Mandatory = $true)]
        [string]$regexPattern
    )

    # Ensure output directory exists
    if (-not (Test-Path $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }

    # Get all files in the source directory recursively
    $files = Get-ChildItem -Path $exportFolder -Recurse -File
    foreach ($file in $files) {
        Write-Progress -Activity "Searching files for $regexPattern" -Status "File $($fileIndex) of $($files.count)" -PercentComplete $(($fileIndex / $files.count) * 100)
        $fileIndex += 1
        # Read file content as a single string
        $content = [System.IO.File]::ReadAllText($file.FullName)

        # Check if content matches the regex pattern
        if ($content -match $regexPattern) {
            $fileMatchCount++
            Write-host "Copying file: $($file.FullName) to $OutputDirectory"
            $destination = Join-Path $OutputDirectory $file.Name
            Copy-Item -Path $file.FullName -Destination $destination -Force
            Copy-RelatedAssets -HtmlFilePath $file.FullName -exportFolder $exportFolder -OutputDirectory $outputDirectory
        }
    }
    Write-Host "Total files copied: $fileMatchCount"
    Write-Progress -Activity "Completed" -Completed
}

