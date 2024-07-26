# Define variables
$imageName = "ipdr-server"
$containerName = "ipdr-server"
$dockerfilePath = ".."
$originalPath = Get-Location

# Change to the Dockerfile directory
Push-Location $dockerfilePath

try {
    # Build the Docker image
    Write-Host "Building the Docker image..."
    docker build -t $imageName .

    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed. Exiting."
    }

    # Check if a container with the same name is already running
    Write-Host "Checking for existing container..."
    $existingContainer = docker ps -aq --filter "name=$containerName"

    if ($existingContainer) {
        Write-Host "Stopping and removing existing container..."
        docker stop $containerName
        docker rm $containerName

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to stop and remove existing container. Exiting."
        }
    }

    # Run the Docker container
    Write-Host "Running the Docker container..."
    #docker run -d -p 5000:5000 -p 4001:4001 -p 8080:8080 -p 5001:5001 --name $containerName $imageName
    docker run -d -p 5000:5000 -e BOOTSTRAP=/dns4/ipfs.metadata.box/tcp/443/wss/p2p/12D3KooWLgrGC22HbjWKfAUJ2xpRt6vXzCtuajsjih1FWYzeSjyG --name $containerName $imageName

    if ($LASTEXITCODE -ne 0) {
        throw "Docker run failed. Exiting."
    }

    Write-Host "Docker container $containerName is up and running."
}
catch {
    Write-Host $_
    exit $LASTEXITCODE
}
finally {
    # Ensure to return to the original path
    Pop-Location
}
