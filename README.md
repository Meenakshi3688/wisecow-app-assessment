# Cow wisdom web server

## Prerequisites

```
sudo apt install fortune-mod cowsay -y
```

## How to use?

1. Run `./wisecow.sh`
2. Point the browser to server port (default 4499)

## What to expect?
![wisecow](https://github.com/nyrahul/wisecow/assets/9133227/8d6bfde3-4a5a-480e-8d55-3fef60300d98)

# Problem Statement
Deploy the wisecow application as a k8s app

Requirement
Create Dockerfile for the image and corresponding k8s manifest to deploy in k8s env. The wisecow service should be exposed as k8s service.
Github action for creating new image when changes are made to this repo
[Challenge goal]: Enable secure TLS communication for the wisecow app.

## Expected Artifacts
1. Github repo containing the app with corresponding dockerfile, k8s manifest, any other artifacts needed.
2. Github repo with corresponding github action.
3. Github repo should be kept private and the access should be enabled for following github IDs: nyrahul


# Implementation Details

This section describes the implementation of both problem statements.

# Problem Statement 1 – Implementation
---

# Implementation Details

This section describes the implementation of the two problem statements for DevOps Trainee Practical Assessment.

# Problem Statement 1: Containerize and Deploy Wisecow Application on Kubernetes

## 1. Objective

The objective is to containerize the Wisecow application using Docker, deploy it on Kubernetes, automate the build and deployment process using GitHub Actions, and enable secure HTTPS communication using TLS.

## 2. Technologies Used

- AWS EC2
- Ubuntu Linux
- Docker
- Docker Hub
- Kubernetes
- NGINX Ingress Controller
- GitHub Actions
- OpenSSL
- Git and GitHub
- YAML

## 3. Docker Containerization

Created a Dockerfile to package the Wisecow application and its required dependencies into a Docker image.

The Dockerfile uses Ubuntu 24.04 as the base image and installs the following packages:

- `fortune-mod` – generates random fortunes.
- `cowsay` – displays fortunes in a cow-themed format.
- `netcat-openbsd` – provides networking utilities.

### Dockerfile

```dockerfile
FROM ubuntu:24.04

WORKDIR /app

RUN apt-get update && \
    apt-get install -y fortune-mod cowsay netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/games:${PATH}"

COPY wisecow.sh .

RUN chmod +x wisecow.sh

EXPOSE 4499

CMD ["bash", "wisecow.sh"]
```

### Build Docker Image

```bash
docker build -t wisecow:v1 .
```

### Run Docker Container

```bash
docker run -d -p 4499:4499 wisecow:v1
```

### Verify Docker Container

```bash
docker ps
docker images
```

### Docker Hub Repository

Docker image repository:

https://hub.docker.com/r/badigerm/wisecow

The GitHub Actions workflow publishes the `latest` tag and a commit-specific image tag to Docker Hub.

## 4. Kubernetes Deployment

Deployed the Wisecow application on a single-node Kubernetes cluster running on AWS EC2.

Created Kubernetes manifests to manage the application.

### Kubernetes Resources

**Deployment**

- Creates and manages the Wisecow application pod.
- Maintains the desired number of replicas.
- Uses the Docker image stored in Docker Hub.

**NodePort Service**

- Exposes the application outside the Kubernetes cluster.
- Forwards external traffic to the application running on port `4499`.
- Uses NodePort `30080`.

### Kubernetes Manifest

File: `k8s/wisecow.yaml`

The manifest contains the Deployment and NodePort Service configurations.

### Deploy the Application

```bash
kubectl apply -f k8s/wisecow.yaml
```

### Verify Kubernetes Resources

```bash
kubectl get nodes
kubectl get deployments
kubectl get pods
kubectl get services
```

### Check Deployment Status

```bash
kubectl rollout status deployment/wisecow
```

## 5. CI/CD Automation Using GitHub Actions

Implemented a GitHub Actions workflow to automate Docker image building, publishing, and Kubernetes deployment.

Workflow file:

`.github/workflows/docker-build-push.yml`

### Continuous Integration (CI)

The CI process performs the following steps:

1. Checks out the source code from GitHub.
2. Sets up Docker Buildx.
3. Authenticates with Docker Hub using GitHub Secrets.
4. Builds the Docker image.
5. Pushes the image to Docker Hub.

The workflow publishes two image tags:

- `badigerm/wisecow:latest`
- `badigerm/wisecow:<commit-sha>`

### Continuous Deployment (CD)

The CD process performs the following steps:

1. Waits for the Docker image build and push job to complete.
2. Runs on a self-hosted GitHub Actions runner installed on the AWS EC2 instance.
3. Updates the Kubernetes Deployment with the newly created Docker image.
4. Checks the rollout status to verify successful deployment.

### GitHub Actions Workflow

The workflow is triggered when changes are pushed to the `main` branch. It also supports manual execution using `workflow_dispatch`.

### GitHub Secrets

The following credentials are configured under GitHub repository Settings → Secrets and variables → Actions:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

Credentials are not stored directly in the workflow file.

## 6. NGINX Ingress and TLS Configuration

Configured NGINX Ingress Controller to manage external HTTP and HTTPS traffic to the Wisecow application.

### NGINX Ingress Controller

Installed the NGINX Ingress Controller using the Kubernetes bare-metal deployment manifest.

The controller exposes the following NodePorts:

| Protocol | NodePort |
|---|---:|
| HTTP | 31817 |
| HTTPS | 32177 |

### TLS Certificate Generation

Generated a self-signed TLS certificate using OpenSSL.

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout wisecow-tls.key \
  -out wisecow-tls.crt \
  -subj "/CN=52.66.255.103.nip.io" \
  -addext "subjectAltName=DNS:52.66.255.103.nip.io"
```

### Create Kubernetes TLS Secret

```bash
kubectl create secret tls wisecow-tls \
  --cert=wisecow-tls.crt \
  --key=wisecow-tls.key
```

### Ingress Configuration

File: `k8s/wisecow-ingress.yaml`

Configured the Ingress resource with:

- Hostname: `52.66.255.103.nip.io`
- TLS Secret: `wisecow-tls`
- Backend Service: `wisecow-service`
- Backend Port: `4499`

The Ingress routes incoming HTTPS traffic to the Wisecow Kubernetes Service.

### Apply Ingress Configuration

```bash
kubectl apply -f k8s/wisecow-ingress.yaml
```

### Verify Ingress and TLS Secret

```bash
kubectl get ingress
kubectl get pods -n ingress-nginx
kubectl get services -n ingress-nginx
kubectl get secrets
```

### Application HTTPS URL

https://52.66.255.103.nip.io:32177

**Note:**

- The project uses a self-signed certificate, so the browser may display a security warning.
- HTTPS encryption is enabled, but the certificate is not trusted by public certificate authorities.
- The hostname uses nip.io DNS and the EC2 public IP.
- If the EC2 public IP changes, the hostname, certificate, and Ingress configuration need to be updated.
- The EC2 Security Group must allow the required NodePort traffic.

---

# Problem Statement 2: Bash Scripting

Selected and implemented the following two tasks using Bash scripting:

1. System Health Monitoring Script.
2. Application Health Checker.

## 1. System Health Monitoring Script

File: `scripts/system-health-monitor.sh`

### Objective

Developed a Bash script to monitor important Linux system resources and generate alerts when resource usage exceeds predefined thresholds.

### Metrics Monitored

**CPU Usage**

Uses `vmstat` to calculate CPU utilization.

**Memory Usage**

Uses the `free` command to calculate memory utilization.

**Disk Usage**

Uses the `df` command to check root filesystem disk utilization.

**Running Processes**

Uses `ps` to count the currently running processes.

### Alert Thresholds

| Metric | Threshold |
|---|---:|
| CPU Usage | 80% |
| Memory Usage | 80% |
| Disk Usage | 80% |
| Running Processes | 250 |

The script displays an alert when a metric exceeds its configured threshold. Otherwise, it displays an OK status.

### Execute the Script

```bash
chmod +x scripts/system-health-monitor.sh

./scripts/system-health-monitor.sh
```

### Sample Output

```text
===== System Health Monitoring =====

CPU Usage: 3%
Memory Usage: 15%
Disk Usage: 34%
Running Processes: 204

===== Health Alerts =====

OK: CPU usage is normal.
OK: Memory usage is normal.
OK: Disk usage is normal.
OK: Process count is normal.

Health check completed.
```

### Key Features

- Monitors CPU utilization.
- Monitors memory utilization.
- Monitors disk utilization.
- Counts running processes.
- Generates threshold-based alerts.
- Displays the monitoring date and time.

## 2. Application Health Checker

File: `scripts/application-health-checker.sh`

### Objective

Developed a Bash script to check the availability of the deployed Wisecow application using HTTPS requests and HTTP response status codes.

### Working

The script uses `curl` to send an HTTPS request to the deployed application.

It checks the HTTP response status code:

- HTTP 200 – Application is UP.
- Any other response or connection failure – Application is DOWN.

### Execute the Script

```bash
chmod +x scripts/application-health-checker.sh

./scripts/application-health-checker.sh
```

### Sample Output

```text
Checking Application Health...
Application is UP
```

### Key Features

- Checks application availability.
- Uses HTTPS for communication.
- Validates HTTP response status codes.
- Follows HTTP redirects.
- Uses connection and request timeouts.
- Displays application status as UP or DOWN.

**Note:** In this project, I used the EC2 private IP with the `curl --resolve` option to check the application. I also used `-k` because I configured a self-signed TLS certificate. If the EC2 IP address changes, I need to update the IP and hostname in the script. These configurations are used for this practice project.

---

# Repository Structure

```text
wisecow-app-assessment/
│
├── .github/
│   └── workflows/
│       └── docker-build-push.yml
│
├── k8s/
│   ├── wisecow.yaml
│   └── wisecow-ingress.yaml
│
├── scripts/
│   ├── system-health-monitor.sh
│   └── application-health-checker.sh
│
├── Dockerfile
├── .dockerignore
├── wisecow.sh
├── LICENSE
└── README.md
```

# Security Considerations

- Docker Hub credentials are stored securely using GitHub Actions Secrets.
- Kubernetes kubeconfig is not committed to the GitHub repository.
- TLS private key and certificate files are not committed to the repository.
- The self-hosted GitHub Actions runner should be restricted to the assessment repository.
- The TLS certificate used in this lab is self-signed and not publicly trusted.
- The EC2 Security Group should allow only the required inbound traffic.

# Conclusion

Successfully implemented the Wisecow application deployment using Docker and Kubernetes, automated CI/CD using GitHub Actions, and configured HTTPS communication using NGINX Ingress and TLS.

Additionally, developed two Bash scripts for Linux system resource monitoring and application availability checking.

This project provided practical experience with containerization, Kubernetes orchestration, CI/CD automation, cloud infrastructure, TLS configuration, and Linux shell scripting.
3. [Challenge goal]: Enable secure TLS communication for the wisecow app.

