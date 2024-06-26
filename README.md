<h3 align="center">
  <br />
  <img src="https://user-images.githubusercontent.com/168240/52895983-7330f100-3176-11e9-855c-246eaabd3adc.png" alt="logo" width="600" />
  <br />
  <br />
  <br />
</h3>

# IPDR: InterPlanetary Docker Registry

> [IPFS](https://github.com/ipfs/go-ipfs)-backed [Docker](https://github.com/docker/docker) Registry

[![License](http://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/ipdr/ipdr/master/LICENSE)
[![CircleCI](https://circleci.com/gh/ipdr/ipdr.svg?style=svg)](https://circleci.com/gh/ipdr/ipdr)
[![Go Report Card](https://goreportcard.com/badge/github.com/ipdr/ipdr?)](https://goreportcard.com/report/github.com/ipdr/ipdr)
[![GoDoc](https://godoc.org/github.com/ipdr/ipdr?status.svg)](https://godoc.org/github.com/ipdr/ipdr)
[![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/emersion/stability-badges#experimental)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

IPDR is a [Docker Registry](https://docs.docker.com/registry/) tool that proxies Docker registry requests to IPFS for pushing and pulling images. IPDR allows you to store Docker images on IPFS instead of a central registry like Docker Hub or Google Container Registry. Docker images are referenced by their IPFS hash instead of the repo tag names.

IPDR is compatabile with the *Docker Registry HTTP [API V2 Spec](https://docs.docker.com/registry/spec/api/)* for pulling images&ast;

<sup><sub>&ast;not fully 1:1 implemented yet</sub></sup>

High-level overview:

<img src="https://user-images.githubusercontent.com/168240/52923314-14858780-32dc-11e9-80f8-9a0025de6090.png" alt="logo" width="500" />

## Contents

- [Getting started](#getting-started)
- [CLI](#cli)
- [FAQ](#faq)
- [Contributing](#contributing)
- [Resources](#resources)
- [License](#license)


## Getting Started

IPDR can be used in two main ways:

1. **Using the Local Registry Container:** This method involves setting up IPDR registry. The IPDR registry contains the IPDR server and an IPFS node
2. **Using the IPDR Client with an IPFS Node:** This standalone method requires only an IPFS Desktop Node and the IPDR client.

## Using IPDR with an IPFS Node

This setup allows you to use IPDR directly with an existing IPFS node, enabling Docker image management through IPFS without a full registry setup.

### Installation

Install the IPDR client on your system to interact with IPFS directly:

#### For Linux:
```bash
# Download the latest release binaries
wget https://github.com/Metazla/ipdr/releases/download/x.x.x/ipdr_x.x.x_linux_amd64.tar.gz
tar -xvzf ipdr_x.x.x_linux_amd64.tar.gz
sudo mv ipdr /usr/local/bin/ipdr

# Check installation
ipdr --help
```

#### For Windows:
Download the executable from [IPDR Releases](https://github.com/Metazla/ipdr/releases) and add it to your system path.

#### Using Go:
If you have Go installed, you can install directly using:
```bash
go get -u github.com/Metazla/ipdr/cmd/ipdr
```

### Usage

With IPDR installed, and the IPFS node running (must listen on the 5000 port API) you can push and pull Docker images to and from IPFS. Here’s how you can use the IPDR client:

```bash
# Build a Docker image
docker build -t example/helloworld .

# Push the image to IPFS and get the IPFS hash
ipdr push example/helloworld

# On another machine, pull the image from IPFS using the hash
ipdr pull bafybeidb5pvdpggchtwj2pacw7zyxf7wtwotktrw6dn3iqtpbdktlb4diy

# Run the Docker image
docker run example/helloworld
```

## Setting Up the IPDR Registry Container

The IPDR registry container integrates an IPFS node with the Docker registry capabilities provided by IPDR, facilitating a seamless Docker image management experience.

### Installation

1. **Download the latest Docker image:**
   - From GitHub: Navigate to [IPDR Releases](https://github.com/Metazla/ipdr/releases) and download the appropriate image file.
   - Directly from IPFS: Download using the IPFS hash provided in the releases page and rename the file to `file.tar`.

2. **Load and start the registry:**
```bash
docker load --input file.tar
docker run -d -p 5000:5000 ipdr-server:latest
```

### Usage

Once the registry is running, you can tag, push, and pull images:

```bash
# Tag your Docker image
docker tag example/helloworld localhost:5000/example/helloworld

# Push the image to IPFS via the IPDR registry
docker push localhost:5000/example/helloworld

# Pull the image to IPFS via the IPDR registry
docker pull localhost:5000/example/helloworld

# Pull and run the image from IPFS via your registry
docker run localhost:5000/example/helloworld
```

## CLI

```bash
$ ipdr --help

The command-line interface for the InterPlanetary Docker Registry.
More info: https://github.com/ipdr/ipdr

Usage:
  ipdr [flags]
  ipdr [command]

Available Commands:
  convert     Convert a hash to IPFS format or Docker registry format
  help        Help about any command
  pull        Pull image from the IPFS-backed Docker registry
  push        Push image to IPFS-backed Docker registry
  server      Start IPFS-backed Docker registry server

Flags:
  -h, --help   help for ipdr

Use "ipdr [command] --help" for more information about a command.
```

### Example flow

- Create `Dockerfile`:

    ```dockerfile
    FROM busybox:latest

    CMD echo 'hello world'
    ```

- Build Docker image:

    ```bash
    docker build -t example/helloworld .
    ```

    Test run:

    ```bash
    $ docker run example/helloworld:latest
    hello world
    ```

- Use IPDR CLI to push to IPFS:

    ```bash
    $ ipdr push example/helloworld

    INFO[0000] [registry] temp: /var/folders/k1/m2rmftgd48q97pj0xf9csdb00000gn/T/205139235
    INFO[0000] [registry] preparing image in: /var/folders/k1/m2rmftgd48q97pj0xf9csdb00000gn/T/657143846
    INFO[0000]
    [registry] dist: /var/folders/k1/m2rmftgd48q97pj0xf9csdb00000gn/T/657143846/default/blobs/sha256:305510b2c684403553fd8f383e8d109b147df2cfde60e40a85564532c383c8b8
    INFO[0000] [registry] compressing layer: /var/folders/k1/m2rmftgd48q97pj0xf9csdb00000gn/T/205139235/886f4bdfa483cc176e947c63d069579785c051793a9634f571fded7b9026cd3c/layer.tar
    INFO[0000] [registry] root dir: /var/folders/k1/m2rmftgd48q97pj0xf9csdb00000gn/T/657143846
    INFO[0000] [registry] upload hash QmRxZ5Wffj6b1j8ckJLcr7yFrbHUhBYXsAMbj7Krwu1pp8
    INFO[0000]
    [registry] uploaded to /ipfs/Qmc2ot2NQadXmbvPbsidyjYDvPfPwKZmovzNpfRPKxXUrL
    INFO[0000] [registry] docker image ciqmw4mig2uwaygddjlutoywq43udutvdmuxkcxvetsjp2mjdde27wi

    Successfully pushed Docker image to IPFS:
    /ipfs/Qmc2ot2NQadXmbvPbsidyjYDvPfPwKZmovzNpfRPKxXUrL
    ```

- Use IPDR CLI to pull from IPFS:

    ```bash
    $ ipdr pull /ipfs/QmagW4H1uE5rkm8A6iVS8WuiyjcWQzqXRHbM3KuUfzrCup

    INFO[0000] [registry/server] port 5000
    INFO[0000] [registry] attempting to pull docker.local:5000/ciqmw4mig2uwaygddjlutoywq43udutvdmuxkcxvetsjp2mjdde27wi
    INFO[0000] [registry/server] /v2/
    INFO[0000] [registry/server] /v2/ciqmw4mig2uwaygddjlutoywq43udutvdmuxkcxvetsjp2mjdde27wi/manifests/latest
    INFO[0000] [registry/server] location http://127.0.0.1:8080/ipfs/Qmc2ot2NQadXmbvPbsidyjYDvPfPwKZmovzNpfRPKxXUrL/manifests/latest-v2
    {"status":"Pulling from ciqmw4mig2uwaygddjlutoywq43udutvdmuxkcxvetsjp2mjdde27wi","id":"latest"}
    {"status":"Digest: sha256:1fb36e4704d6ebad5becdcfe996807de5f8db687da396330f112157c888c165b"}
    {"status":"Status: Downloaded newer image for docker.local:5000/ciqmw4mig2uwaygddjlutoywq43udutvdmuxkcxvetsjp2mjdde27wi:latest"}

    Successfully pulled Docker image from IPFS:
    docker.local:5000/ciqmw4mig2uwaygddjlutoywq43udutvdmuxkcxvetsjp2mjdde27wi
    ```

- Run image pulled from IPFS:

    ```bash
    $ docker run docker.local:5000/ciqmw4mig2uwaygddjlutoywq43udutvdmuxkcxvetsjp2mjdde27wi
    hello world
    ```

- Retag Docker image:

    ```bash
    $ docker tag docker.local:5000/ciqmw4mig2uwaygddjlutoywq43udutvdmuxkcxvetsjp2mjdde27wi example/helloworld:latest
    ```

- We can also pull the image using `docker pull`:
    - First run the IPDR server in a seperate terminal:

        ```bash
        $ ipdr server -p 5000
        INFO[0000] [registry/server] listening on [::]:5000
        ```

    - Then convert the IPFS hash to a valid format docker allows:

        ```bash
        $ ipdr convert QmYMg6WAuvF5i5yFmjT8KkqewZ5Ngh4U9Mp1bGfdjraFVk --format=docker

        ciqjjwaeoszdgcaasxmlhjuqnhbctgwijqz64w564lrzeyjezcvbj4y
        ```

    - Now we can `docker pull` the image from IPFS:

        ```bash
        $ docker pull docker.local:5000/ciqjjwaeoszdgcaasxmlhjuqnhbctgwijqz64w564lrzeyjezcvbj4y
        Using default tag: latest
        latest: Pulling from ciqjjwaeoszdgcaasxmlhjuqnhbctgwijqz64w564lrzeyjezcvbj4y
        Digest: sha256:6b787c9e04c2038d4b3cb0392417abdddfcfd88e10005d970fc751cdcfd6d895
        Status: Downloaded newer image for docker.local:5000/ciqjjwaeoszdgcaasxmlhjuqnhbctgwijqz64w564lrzeyjezcvbj4y:latest
        ```

        Test run:

        ```bash
        $ docker run docker.local:5000/ciqjjwaeoszdgcaasxmlhjuqnhbctgwijqz64w564lrzeyjezcvbj4y
        hello world
        ```

## IPNS

An example of using IPNS to resolve image tag names.

1. First start local server:

```bash
ipdr server -p 5000
```

2. Tag the image:

```bash
docker pull hello-world
docker tag hello-world docker.local:5000/hello-world
```

3. Push to local registry:

```bash
docker push --quiet docker.local:5000/hello-world
```

CID mappings live under `~/.ipdr`

```bash
$ tree ~/.ipdr/
/home/username/.ipdr/
└── cids
    └── hello-world
        └── latest
```

4. Add cids directory to IPFS:

```bash
$ ipfs add -r ~/.ipdr/cids/ --quieter
QmVtjwa3kdFJHce2wnFuygaCHdSPXraBd4FRSEZKjqZWQp
```

5. Set `_dnslink` TXT record on the domain to point to the directory IPFS hash:

```
dnslink=/ipfs/QmVtjwa3kdFJHce2wnFuygaCHdSPXraBd4FRSEZKjqZWQp
```

6. Verify DNS changes:

```bash
$ dig _dnslink.example.com -t TXT +short
"dnslink=/ipfs/QmVtjwa3kdFJHce2wnFuygaCHdSPXraBd4FRSEZKjqZWQp"
```

7. Re-run server, now with domain as resolver:

```bash
$ ipdr server --cid-resolver=example.com
```

8. Now we can run ipdr dig to get CID using repo tag name!

```bash
$ ipdr dig hello-world:latest
bafybeiakvswzlopeu573372p5xry47tkc2hhcg5q5rulmbfrnkecrbnt3y
```

Note: if nothing is returned, then make sure the IPFS gateway is correct.

9. Next pull and the docker image from IPFS using the resolved CID formatted for docker:

```bash
docker pull docker.local:5000/bafybeiakvswzlopeu573372p5xry47tkc2hhcg5q5rulmbfrnkecrbnt3y
docker run docker.local:5000/bafybeiakvswzlopeu573372p5xry47tkc2hhcg5q5rulmbfrnkecrbnt3y
```

## Social

- Discuss on [Discord](https://discord.gg/7GJwMjedjh)

## Resources

- [Docker Registry HTTP API V2 Spec](https://docs.docker.com/registry/spec/api/)
- [Docker Registry 2.0 (slidedeck)](https://www.slideshare.net/Docker/docker-48351569)
- [image2ipfs](https://github.com/jvassev/image2ipfs/)

## FAQ

- Q: How do I configure the local registry host or port that IPDR uses when pushing or pulling Docker images?

  - A: Use the `--docker-registry-host` flag, eg. `--docker-registry-host docker.for.mac.local:5000`

- Q: How do I configure the IPFS host that IPDR uses for pushing Docker images?

  - A: Use the `--ipfs-host` flag, eg. `--ipfs-host 127.0.0.1:5001`

- Q: How do I configure the IPFS gateway that IPDR uses for pulling Docker images?

  - A: Use the `--ipfs-gateway` flag, eg. `--ipfs-gateway https://ipfs.io`

- Q: How can I configure the port for the IPDR registry server?

  - A: Use the `--port` flag, eg. `--port 5000`

- Q: How do I setup HTTPS/TLS on the IPDR registry server?

  - A: Use the `--tlsKeyPath` and `--tlsCertPath` flag, eg. ` --tlsKeyPath path/server.key --tlsCertPath path/server.crt`

- Q: How do I get `docker.local` to work?

  - A: Make sure to add `127.0.0.1  docker.local` to `/etc/hosts`. Optionally, you may use `local.ipdr.io` which resolves to `127.0.0.1`

## Contributing

Pull requests are welcome!

For contributions please create a new branch and submit a pull request for review.

_Many thanks to [@qiangli](https://github.com/qiangli) and all the [contributors](https://github.com/ipdr/ipdr/graphs/contributors) that made this package better._

### building the solution on windows
TODO format
```bash
Start IPFS desktop
Start Docker Desktop
goreleaser release --snapshot --clean
docker build -t example/helloworld .
dist\ipdr_windows_amd64_v1\ipdr.exe push example/helloworld
```

### Test

```bash
make test
```

## License

Released under the [MIT](./LICENSE) license.

© [Miguel Mota](https://github.com/miguelmota)
