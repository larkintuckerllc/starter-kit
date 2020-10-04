# Python

## Issue

Apparently the *tiangolo/meinheld-gunicorn* image requires a RW filesystem. The fix is either research how to run this image in RO mode, find another base image, or hack in a workaround in the *workloads* module to accommodate *python* workloads.

## Update

We first need to update *tf/post-cluster/modules/workloads/* to supply a placeholder Python image:

```hcl
locals {
  name     = "workload"
  platform_image = {
    go     = "sckmkny/starter-kit-image-go:1.0.0"
    nodejs = "sckmkny/starter-kit-image-nodejs:1.0.0"
    python = "sckmkny/starter-kit-image-python:1.0.0"
  }
}
```

We first need to update the *platform_dockerfile* local in *tf/post-cluster/modules/cd/*:

```hcl
  platform_dockerfile = {
    go     = <<EOF
          FROM golang:1.14 AS builder
          WORKDIR /go/src/app
          COPY go.mod go.sum ./
          RUN go mod download
          COPY . .
          RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install -v ./cmd/...

          FROM alpine:3.12
          COPY --from=builder /go/bin/* /usr/local/bin/
          EXPOSE 8080
          USER 1000:1000
          ENV PORT=8080
          CMD ["app"]
    EOF
    nodejs = <<EOF
          FROM node:12.18.2
          WORKDIR /usr/src/app
          COPY package*.json ./
          RUN npm install
          COPY . .
          EXPOSE 8080
          USER 1000:1000
          ENV PORT=8080
          CMD [ "npm", "start" ]
    EOF
    python = <<EOF
          FROM tiangolo/meinheld-gunicorn:python3.8
          COPY requirements.txt /app
          RUN pip install -r requirements.txt
          COPY app /app
          EXPOSE 8080
          USER 1000:1000
          ENV PORT=8080
    EOF
  }
```

We also need to update the *platform_version* local:

```hcl
  platform_version = {
    go     = "$(cat VERSION)"
    nodejs = "$(node -p \"require('./package.json').version\")"
    python = "$(cd app && python -c \"import app; print(app.__version__)\")"
  }
```

## Python Workload Additional Specifications

To be used as the code for a Starter Kit workload, Python projects must additionally:

- Operable with Python 3.8

- Include a *requirements.txt* file

- The *requirements.txt* file must include used dependencies

- Code delivered as a package in the folder *app/app*

- Package to include a module; file *\__init__.py*

- *\__init__.py* module constains a variable *\__variable__* with version; semantic versioning recommended

- Package to include a module; file *main.py*

- *main.py* module contains a variable *app* with a WSGI application

The [Starter Kit Image Python](https://github.com/larkintuckerllc/starter-kit-image-python) project provides a minimal example satisfying these requirements.

**note**: This application responds with a HTTP status code 200 (OK) for unadorned GET requests on any endpoint.
