# Documentation (0.2.0)

## Workload Specification

Workloads are defined in the file *tf/post-cluster/terraform.tfvars* under the *workload* attribute, e.g.:

```hcl
workload        = {
  sample = {
    external             = true
    limits_cpu           = "100m"
    limits_memory        = "128Mi"
    liveness_probe_path  = "/"
    readiness_probe_path = "/"
    replicas             = 1
    requests_cpu         = "100m"
    requests_memory      = "128Mi"
  }
}
```

The workload's key, e.g, *sample*, must be a unique (across the infrastructure) name. The name must be a valid hostname format; [hostname(7) — Linux manual page](https://man7.org/linux/man-pages/man7/hostname.7.html). The required attributes are:

- *external*: Boolean value indicating if the workload is publically available, *true*, or not *false*. If publically available, it is available through HTTPS on an URL constructed using the key and the *zone_name* configured in the infrastructure, e.g., *https://sample.example.com*. In either case, it is available privately (from other workloads) through HTTP on an URL constructed using only the key, e.g., *http://sample*

- *limits_cpu*: String value. The maximum CPU allocated to the workload. For details on this value, and other cpu and memory attributes, see [Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

- *limits_memory*: String value. The maximum memory allocated to the workload

- *liveness_probe_path*: String value. See discussion below

- *readiness_probe_path*: String value. See discussion below

- *replicas*: Integral value greater than 0. The number of instances of the workload to run

- *requests_cpu*: String value. The minimum CPU available to the workload

- *requests_memory*: String value. The minimum memory available to the workload

To be used as the code for a Starter Kit workload, projects must:

- Application listens to HTTP traffic on the port specified by the *PORT* environment variable

- Application can run as an unpriviliged user / group (specifically with UID / GID 1000)

- Application can run on a read-only file system

- Application provides an endpoint that returns a HTTP status code 200 (OK) for unadorned GET requests, i.e., no headers, query parameters, etc. This endpoint is used regularly to determine the health of the application. Used as a Kubernetes [liveness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command). This is used for the *liveness_probe_path* attribute and optionally the *readiness_probe_path*

- (optional) Application provides a second endpoint that returns a HTTP status code 200 (OK) for unadorned GET requests, i.e., no headers, query parameters, etc. This endpoint is used regularly to determine the readiness of the application. Used as a Kubernetes [readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes). This is used for the *readiness_probe_path*

## Node.js Workload Additional Specifications

To be used as the code for a Starter Kit workload, Node.js projects must additionally:

- Operable with Node.js 12.18.2

- Include a *package.json* file

- The *package.json* file must include a *version* attribute; semantic versioning recommended

- The *package.json* file must include a *start* script attribute

- The *package.json* file must include dependencies in the *dependencies* attribute

- Include a *.gitignore* file

- The *.gitignore* file must include *node_modules* line

- (recommended) Include a *package-lock.json*

The [Starter Kit Image Node.js](https://github.com/larkintuckerllc/starter-kit-image-nodejs) project provides a minimal example satisfying these requirements.

**note**: This application responds with a HTTP status code 200 (OK) for unadorned GET requests on any endpoint.
