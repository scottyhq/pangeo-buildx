group "default" {
   targets = ["base-notebook"]
}

# Dockerfile relative to context directory
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
