# Docker build manual

[Home Control](README.md) | [How to Install](INSTALL.md) | [Docker build manual](BUILD.md) | [Changelog](CHANGELOG.md)

## Multiplatform build for amd64/arm/arm64

1. create new docker builder that supports mutiplaform builds
  > `docker buildx create --name multiplatform --driver=docker-container`

2. login to https://hub.docker.com/
  > `docker login`

3. build the version with the version tag and push it to docker hub
  > `docker buildx build --tag robertcigan/home_control:3.4.1 --platform linux/arm64,linux/arm,linux/amd64 --builder multiplatform --push .`
