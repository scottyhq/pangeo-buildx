# Pangeo buildx experiment

proof of concept using  docker buildx for streamlined images without ONBUILD to simplify things and make the recipe for creating images more transparent.

goals:
- better instruction cache (if only changing 'start' don't reinstall conda environment)
- cache conda packages
  - if one package changes don't re-download everything
  - reuse downloaded packages from pangeo-notebook when creating ml-notebook
- remote Dockerfile / buildcontext for different repositories?

take advantage of new Dockerfile features:
- https://www.docker.com/blog/dockerfiles-now-support-multiple-build-contexts/
- https://www.docker.com/blog/image-rebase-and-improved-remote-cache-support-in-new-buildkit/
- https://www.docker.com/blog/advanced-dockerfiles-faster-builds-and-smaller-images-using-buildkit-and-multistage-builds/

Important Dockerfile Syntax Documentation
https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md

## Usage:
```
base-notebook
docker buildx build -f ../Dockerfile ./ -t base-notebook:test

docker buildx build -f Dockerfile ./base-notebook -t base-notebook:test

docker buildx build -f Dockerfile ./pangeo-notebook -t pangeo-notebook:test --progress=plain

docker buildx
```

### Pros
+ [here-doc syntax](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#here-documents)
+ [volume mount/caching options](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#build-mounts-run---mount)

### GitHub Actions

seems taking advantage of local volume cache not an option https://github.com/docker/setup-buildx-action/pull/138 (yet)

can build a bunch of images in parallel in a single step https://github.com/docker/bake-action


### Compatibility with repo2docker / binderhub

repo2docker would need to update build machinery to support buildkit (https://github.com/jupyterhub/repo2docker/issues/875)

possible solutions:

  1. alternative to docker-py that supports buildkit https://github.com/gabrieldemarmiesse/python-on-whales
  2. allow-the docker-saavy to bypass repo2docker altogether (for binderhubs) and pull images directly from public registries https://github.com/jupyterhub/binderhub/issues/1298. Basically just pre-build dockerfiles without repo2docker and point to them. This is effectively what https://github.com/jupyterhub/repo2docker-action is doing.
