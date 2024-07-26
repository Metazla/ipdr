# Define variables
$dockerfilePath = ".."

# Change to the Dockerfile directory
Push-Location $dockerfilePath

try {
    # Build the Docker image
    Write-Host "Building the Docker image..."
    npx wavepush publish
}
catch {
    Write-Host $_
    exit $LASTEXITCODE
}
finally {
    # Ensure to return to the original path
    Pop-Location
}
