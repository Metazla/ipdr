# Define variables
$imageName = "ipdr-server"
$dockerfilePath = ".."
$distPath = "dist"
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

    # Ensure the distribution path exists
    $imageTarDir = "$originalPath/$distPath"
    if (-Not (Test-Path $imageTarDir)) {
        New-Item -ItemType Directory -Path $imageTarDir -Force
        Write-Host "Created directory for image tar: $imageTarDir"
    }

    Write-Host "Save the Docker image to a tar file"
    $imageTarPath = "$originalPath/$distPath/${imageName}.tar"
    docker save $imageName -o $imageTarPath

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to save Docker image. Exiting."
    }

    Write-Host "Add image tar to IPFS"
    $ipfsAddResult = ipfs add $imageTarPath | Select-String -Pattern "added (\w+) ${imageName}.tar" -AllMatches
    $ipfsCID = $ipfsAddResult.Matches.Groups[1].Value

    if (!$ipfsCID) {
        throw "Failed to add file to IPFS. Exiting."
    }

    Write-Host "Rename the tar file with IPFS CID"
    $ipfsTarPath = "${originalPath}/$distPath/${ipfsCID}.tar"
    Rename-Item -Path $imageTarPath -NewName $ipfsTarPath

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to rename file. Exiting."
    }

    Write-Host "Docker image saved and added to IPFS with CID: $ipfsCID"
}
catch {
    Write-Host $_
    exit $LASTEXITCODE
}
finally {
    # Ensure to return to the original path
    Pop-Location
}
