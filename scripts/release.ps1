param(
    [string]$BuildName = "Axis",
    [string]$BuildNumber = "1.3.0"
)

$ErrorActionPreference = "Stop"

Write-Host "Axis release build (Windows)" -ForegroundColor Cyan

$args = @("build", "windows", "--release")
if ($BuildName -ne "") {
    $args += "--build-name=$BuildName"
}
if ($BuildNumber -ne "") {
    $args += "--build-number=$BuildNumber"
}

flutter clean
flutter pub get
flutter @args

$output = Join-Path $PSScriptRoot "..\build\windows\x64\runner\Release"
Write-Host "Build completed: $output" -ForegroundColor Green