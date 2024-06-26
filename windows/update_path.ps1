param (
    [string]$Path
)

$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if (-not $currentPath.Contains($Path)) {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$Path", [EnvironmentVariableTarget]::User)
}

# Refresh environment variables
$shell = New-Object -ComObject WScript.Shell
$env = $shell.Environment("User")
$env.Item("Path") = [System.Environment]::GetEnvironmentVariable("Path", "User")
