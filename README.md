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

## Problem statement 2 - Writing bash scripts

Each script has parameters that can be configured using environment
variables. All scripts have dependency checks built-in. The scripts will
error out in case any of the required dependencies are missing.

1. [x] System Health Monitoring Script

Solution: [script](./scripts/health-monitor)

| Environment variable                                 | Default value       |
|------------------------------------------------------|---------------------|
| CPU_USED_THRESHOLD                                   | 80 (in percent)     |
| MEM_USED_THRESHOLD                                   | 80 (in percent)     |
| DISK_USED_THRESHOLD                                  | 80 (in percent)     |
| PROCESS_COUNT_THRESHOLD                              | 600                 |
| MOUNT_POINT (where disk usage needs to be monitored) | /                   |
| LOG_FILE                                             | /var/log/health.log |
| CHECK_INTERVAL                                       | 10s                 |

```
$ LOG_FILE=/tmp/foo.log PROCESS_COUNT_THRESHOLD=10 ./scripts/health-monitor
time=Wed Aug 14 09:24:08 PM IST 2024 type=ALERT msg=process count exceeded 10: 272
```

2. [x] Automated Backup Solution

Solution: [script](./scripts/backup2s3)

This script used the aws-cli tool to upload backups to s3. It gzips the
source directory before uploading. A cronjob can be setup to automate
backups at regular interval.

Eg: Backup every hour

```
*/60 * * * * /path/to/backup2s3
```

| Environment variable | Default value                                  |
|----------------------|------------------------------------------------|
| SRC_DIR              | REQUIRED. Eg: /var/lib/mydata.db               |
| S3_BUCKET            | REQUIRED. Eg: s3://your-s3-bucket-name/backups |
| LOG_FILE             | /var/log/backup.log                            |

```
$ LOG_FILE=/tmp/foo.log SRC_DIR=/tmp/test/foo S3_BUCKET=s3://mypublicassetstore/backups ./scripts/backup2s3
time=Wed Aug 14 09:39:27 PM IST 2024 id=20240814160915 type=success msg=uploaded backup of /tmp/test/foo to s3 bucket s3://mypublicassetstore/backups
```

**NOTE**: AWS credentials must be configured (`aws configure`) in order
for the script to work.

3. [x] Log File Analyzer

Solution: [script](./scripts/analyse-nginx-log)

This script parses nginx log file (default format) and summarizes the
statistics mentioned in the problem statement. I've provided a sample
log file [here](./data/access.log).

| Environment variable | Default value                                      |
|----------------------|----------------------------------------------------|
| LOG_FILE             | /var/log/nginx/access.log (path to nginx log file) |

```
$ LOG_FILE=./data/access.log ./scripts/analyse-nginx-log
Summary of http status code:
     22 200
     23 301
     14 302
     22 404
     19 500
Top 10 most requested pages:
     23 /contact.html
     20 /about.html
     19 /products.html
     14 /services.html
     12 /index.html
     12 /blog.html
Top 10 ip address with the most requests:
     20 10.0.0.1
     26 10.0.0.2
     12 172.16.0.1
     11 192.168.0.1
     14 192.168.0.2
     17 192.168.0.3
Top 10 user-agents with the most request:
      9 curl/7.68.0
     15 Mozilla/5.0
     35 Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)
     23 Mozilla/5.0 (Windows NT 10.0; Win64; x64)
     18 PostmanRuntime/7.26.8
```

4. [x] Application Health Checker

Solution: [script](./scripts/monitor-web-server)

This script probes a web server url at regular intervals. The parameters
are similar to Kubernetes' health probes.

| Environment variable | Default value           |
|----------------------|-------------------------|
| LOG_FILE             | /var/log/monitoring.log |
| FAILURE_THRESHOLD    | 3                       |
| PERIOD_SECONDS       | 5                       |
| TIMEOUT_SECONDS      | 3                       |

```
wisecow:main[!](shell)$ LOG_FILE=/tmp/foo.log ./scripts/monitor-web-server https://wisecow.murtazau.xyz
time=Wed Aug 14 09:46:57 PM IST 2024 status=up msg=200
time=Wed Aug 14 09:47:02 PM IST 2024 status=up msg=200
time=Wed Aug 14 09:47:07 PM IST 2024 status=up msg=200
```

```
wisecow:main[!](shell)$ LOG_FILE=/tmp/foo.log ./scripts/monitor-web-server https://foolcow.murtazau.xyz
time=Wed Aug 14 09:47:22 PM IST 2024 status=down msg=404
time=Wed Aug 14 09:47:27 PM IST 2024 status=down msg=404
```

```
wisecow:main[!](shell)$ LOG_FILE=/tmp/foo.log ./scripts/monitor-web-server http://timeout.foo
time=Wed Aug 14 09:47:56 PM IST 2024 status=down msg=connection timed out
time=Wed Aug 14 09:48:01 PM IST 2024 status=down msg=connection timed out
time=Wed Aug 14 09:48:06 PM IST 2024 status=down msg=connection timed out
```
