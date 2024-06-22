# Define variables
$imageName = "ipdr-server"
$dockerfilePath = "."
$distPath = "dist"

# Build the Docker image
Write-Host "Building the Docker image..."
docker build -t $imageName $dockerfilePath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed. Exiting."
    exit $LASTEXITCODE
}

Write-Host "Save the Docker image to a tar file"
$imageTarPath = "$distPath/${imageName}.tar"
docker save $imageName -o $imageTarPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to save Docker image. Exiting."
    exit $LASTEXITCODE
}

Write-Host "Add image tar to IPFS"
$ipfsAddResult = ipfs add $imageTarPath | Select-String -Pattern "added (\w+) ${imageName}.tar" -AllMatches
$ipfsCID = $ipfsAddResult.Matches.Groups[1].Value

if (!$ipfsCID) {
    Write-Host "Failed to add file to IPFS. Exiting."
    exit 1
}

Write-Host "Rename the tar file with IPFS CID"
$ipfsTarPath = "${ipfsCID}.tar"
Rename-Item -Path $imageTarPath -NewName $ipfsTarPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to rename file. Exiting."
    exit $LASTEXITCODE
}

Write-Host "Docker image saved and added to IPFS with CID: $ipfsCID"
