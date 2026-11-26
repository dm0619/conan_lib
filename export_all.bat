@echo off
setlocal DisableDelayedExpansion
set "CONAN_EXPORT_ROOT=%~dp0"

powershell.exe -NoLogo -NoProfile -NonInteractive -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "$conan = (Get-Command conan.exe -CommandType Application).Source;" ^
    "$thirdParty = Join-Path $env:CONAN_EXPORT_ROOT 'third_party';" ^
    "$recipes = @(Get-ChildItem -LiteralPath $thirdParty -Directory | Sort-Object Name | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'conanfile.py') -PathType Leaf });" ^
    "if ($recipes.Count -eq 0) { throw ('No Conan recipes found in {0}' -f $thirdParty); }" ^
    "foreach ($recipe in $recipes) {" ^
    "    $json = & $conan inspect $recipe.FullName --format=json --no-remote --lockfile=;" ^
    "    if ($LASTEXITCODE -ne 0) { throw ('Cannot inspect recipe: {0}' -f $recipe.FullName); }" ^
    "    $info = ($json -join [Environment]::NewLine) | ConvertFrom-Json;" ^
    "    $sources = $info.conandata.sources;" ^
    "    if ($sources -isnot [pscustomobject] -or -not $sources.PSObject.Properties.Name) { throw ('No versions found in conandata.yml for {0}. Expected Conan inspect JSON with conandata.sources.' -f $recipe.FullName); }" ^
    "    foreach ($version in $sources.PSObject.Properties.Name) {" ^
    "        Write-Host ('Exporting {0}/{1}' -f $info.name, $version);" ^
    "        & $conan export $recipe.FullName ('--version=' + $version) --no-remote --lockfile=;" ^
    "        if ($LASTEXITCODE -ne 0) { throw ('Export failed: {0}/{1}' -f $info.name, $version); }" ^
    "    }" ^
    "}" ^
    "Write-Host 'All Conan recipes exported successfully.'"
exit /b %errorlevel%
