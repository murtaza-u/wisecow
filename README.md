> I encourage you to check out my homelab K3S cluster git repository, in
> addition to the assignment, to better assess my skills:
> <https://github.com/murtaza-u/infra>

## Problem Statement 1 - Cow wisdom web server

* [x] Dockerization
    * [x] Develop a Dockerfile for creating a container image of the
      Wisecow application. Kubernetes Deployment:
    * [x] Craft Kubernetes manifest files for deploying the Wisecow
      application in a Kubernetes environment.
    * [x] The Wisecow app must be exposed as a Kubernetes service for
      accessibility.
* [x] Continuous Integration and Deployment (CI/CD):
    * [x] Implement a GitHub Actions workflow for:
    * [x] Automating the build and push of the Docker image to a
      container registry whenever changes are committed to the
      repository.
    * [x] Continuous Deployment [Challenge Goal]: Automatically deploy
      the updated application to the Kubernetes environment following
      successful image builds.
* [x] TLS Implementation [Challenge Goal]:
    * [x] Ensure that the Wisecow application supports secure TLS
      communication.

### Write-up

The web server is deployed at <https://wisecow.murtazau.xyz>. Please
note that you'll encounter an invalid certificate warning because I used
self-signed certificates for TLS.

**Generating Self-Signed TLS Certificates:**

```bash
cd certs

# Generate CA certificate and private key
cfssl genkey -initca csr/ca-csr.json | cfssljson -bare ca

# Generate wisecow TLS certificate and private key
cfssl gencert -ca ca.pem -ca-key ca-key.pem csr/wisecow.json | cfssljson -bare wisecow
```

**Important Note:**

Ideally, certificates should never be committed to a Git repository.
However, since this is an assignment, I have done so. In a real-world
scenario, I would likely deploy [cert-manager](https://cert-manager.io/)
and use Let's Encrypt to sign my certificates.

Additionally, I have committed the
[TLS secret](./kubernetes/wisecow/ingress.yaml) to Git. Again, this is due to
the nature of the assignment. In a real-world scenario, I would likely
use something like
[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) to encrypt
secrets before committing them to Git.

**CI/CD:**

I've created two workflows—one to build and push the Docker image to
Docker Hub, and another for Kubernetes CI/CD. The Kubernetes workflow
consists of three jobs that perform the following tasks:

1. Validate the manifest schema using
   [kubeconform](https://github.com/yannh/kubeconform).
2. Run an end-to-end test using Kind.
3. If the above two succeed, deploy the manifests to the Kubernetes
   cluster running in my K3S lab.
