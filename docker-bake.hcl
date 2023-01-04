# Docker buildx bake will build these
group "default" {
   targets = ["base-notebook"]
   #targets = ["base-notebook", "pangeo-notebook", "pytorch-notebook"]
}

# Dockerfile in this repository is relative to context subdirectories
target "base" {
    dockerfile = "../Dockerfile"
}

target "base-notebook" {
    inherits = ["base"]
    context = "./base-notebook"
    tags = ["pangeo/base-notebook:latest"]
}

target "pangeo-notebook" {
    inherits = ["base"]
    context = "./pangeo-notebook"
    tags = ["pangeo/pangeo-notebook:latest"]
}

target "pytorch-notebook" {
    inherits = ["base"]
    context = "./pytorch-notebook"
    tags = ["pangeo/pytorch-notebook:latest"]
}
