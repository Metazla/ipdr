# Define variables
$imageName = "ipdr-server"
$containerName = "ipdr-server"
$dockerfilePath = "."

# Build the Docker image
Write-Host "Building the Docker image..."
docker build -t $imageName $dockerfilePath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed. Exiting."
    exit $LASTEXITCODE
}

# Check if a container with the same name is already running
$existingContainer = docker ps -aq --filter "name=$containerName"

if ($existingContainer) {
    Write-Host "Stopping and removing existing container..."
    docker stop $containerName
    docker rm $containerName
}

# Run the Docker container
Write-Host "Running the Docker container..."
#docker run -d -p 5000:5000 --name $containerName $imageName
docker run -d -p 5000:5000 -p 4001:4001 -p 8080:8080 -p 5001:5001 --name $containerName $imageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker run failed. Exiting."
    exit $LASTEXITCODE
}

Write-Host "Docker container $containerName is up and running."
