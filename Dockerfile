# Use the official Ubuntu image as the base image
FROM ubuntu:latest

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget tar && \
    apt-get clean

# Define the version of Kubo to install
ENV KUBO_VERSION=v0.28.0

# Download and install Kubo
RUN wget https://dist.ipfs.tech/kubo/${KUBO_VERSION}/kubo_${KUBO_VERSION}_linux-amd64.tar.gz && \
    tar -xvzf kubo_${KUBO_VERSION}_linux-amd64.tar.gz && \
    mv kubo/ipfs /usr/local/bin/ipfs && \
    rm -rf kubo_${KUBO_VERSION}_linux-amd64.tar.gz kubo

RUN ipfs init

# Expose the IPFS ports
EXPOSE 4001 5001 8080

RUN apt update && apt install -y tar

WORKDIR /app/

COPY ./dist/ipdr_*_linux_amd64.tar.gz ./ipdr.tar.gz
RUN tar zxvf ./*.tar.gz
RUN chmod +x ./ipdr
RUN mv ./ipdr /usr/local/bin/ipdr

EXPOSE 5000
EXPOSE 4001
ENV DOMAIN www.domain.com

# Set the entrypoint to the ipfs command
#ENTRYPOINT ["ipfs"]
#CMD ["ipfs", "daemon"]
#CMD ["ipdr","server" ]
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]