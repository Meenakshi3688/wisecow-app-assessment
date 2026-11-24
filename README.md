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

---

# Implementation Details

In this section, I have explained how I completed both problem statements for the DevOps Trainee Practical Assessment.

# Problem Statement 1: Containerize and Deploy Wisecow Application on Kubernetes

## 1. Objective

My objective was to containerize the Wisecow application using Docker, deploy it on Kubernetes, automate the build and deployment process using GitHub Actions, and enable HTTPS communication using TLS.

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

First, I created a Dockerfile to package the Wisecow application and its required dependencies into a Docker image.

I used Ubuntu 24.04 as the base image and installed the following packages:

- `fortune-mod` – to generate random fortunes.
- `cowsay` – to display fortunes in a cow-themed format.
- `netcat-openbsd` – to provide networking utilities.

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

I built the Docker image using the following command:

```bash
docker build -t wisecow:v1 .
```

### Run Docker Container

I ran the container and mapped port 4499:

```bash
docker run -d -p 4499:4499 wisecow:v1
```

### Verify Docker Container

I verified the running container and created image using:

```bash
docker ps
docker images
```

### Docker Hub Repository

I created the Wisecow Docker image and pushed it to my Docker Hub repository.

Docker Hub repository:

https://hub.docker.com/r/badigerm/wisecow

I configured GitHub Actions to publish the `latest` tag and a commit-specific image tag to Docker Hub whenever I push changes to the main branch.

## 4. Kubernetes Deployment

After containerizing the application, I deployed Wisecow on a single-node Kubernetes cluster running on AWS EC2.

I created Kubernetes manifests to deploy the application and expose it using a NodePort Service.

### Kubernetes Resources

**Deployment**

I created a Deployment to:

- Create and manage the Wisecow application pod.
- Maintain the desired number of replicas.
- Run the Docker image stored in Docker Hub.

**NodePort Service**

I created a NodePort Service to:

- Expose the application outside the Kubernetes cluster.
- Forward external traffic to the application running on port `4499`.
- Make the application accessible through NodePort `30080`.

### Kubernetes Manifest

File: `k8s/wisecow.yaml`

I defined both the Deployment and NodePort Service configurations in this manifest.

### Deploy the Application

I deployed the application using:

```bash
kubectl apply -f k8s/wisecow.yaml
```

### Verify Kubernetes Resources

I checked the Kubernetes resources using:

```bash
kubectl get nodes
kubectl get deployments
kubectl get pods
kubectl get services
```

### Check Deployment Status

I verified whether the application was deployed successfully using:

```bash
kubectl rollout status deployment/wisecow
```

The deployment was successfully rolled out, and the Wisecow pod was running.

## 5. CI/CD Automation Using GitHub Actions

I implemented a GitHub Actions workflow to automate Docker image building, publishing, and Kubernetes deployment.

Workflow file:

`.github/workflows/docker-build-push.yml`

### Continuous Integration (CI)

I configured the CI job to perform the following steps:

1. Check out the source code from GitHub.
2. Set up Docker Buildx.
3. Authenticate with Docker Hub using GitHub Secrets.
4. Build the Docker image.
5. Push the image to Docker Hub.

I configured the workflow to publish two image tags:

- `badigerm/wisecow:latest`
- `badigerm/wisecow:<commit-sha>`

### Continuous Deployment (CD)

I also configured a CD job to deploy the newly created Docker image to Kubernetes.

For this, I installed and configured a self-hosted GitHub Actions runner on my AWS EC2 instance.

The CD job performs the following steps:

1. Waits for the Docker image build and push job to complete.
2. Runs on my self-hosted GitHub Actions runner.
3. Updates the Kubernetes Deployment with the newly created Docker image.
4. Checks the rollout status to verify successful deployment.

### GitHub Actions Workflow

I configured the workflow to run whenever I push changes to the `main` branch. I also enabled manual execution using `workflow_dispatch`.

### GitHub Secrets

I configured the following secrets under GitHub repository Settings → Secrets and variables → Actions:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

I used GitHub Secrets to store Docker Hub credentials instead of adding them directly to the workflow file.

## 6. NGINX Ingress and TLS Configuration

To enable HTTPS access to my application, I installed and configured the NGINX Ingress Controller.

### NGINX Ingress Controller

I installed the NGINX Ingress Controller using the Kubernetes bare-metal deployment manifest.

The controller exposed the following NodePorts:

| Protocol | NodePort |
|---|---:|
| HTTP | 31817 |
| HTTPS | 32177 |

### TLS Certificate Generation

I generated a self-signed TLS certificate using OpenSSL.

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout wisecow-tls.key \
  -out wisecow-tls.crt \
  -subj "/CN=52.66.255.103.nip.io" \
  -addext "subjectAltName=DNS:52.66.255.103.nip.io"
```

### Create Kubernetes TLS Secret

After generating the certificate, I created a Kubernetes TLS Secret to store the certificate and private key.

```bash
kubectl create secret tls wisecow-tls \
  --cert=wisecow-tls.crt \
  --key=wisecow-tls.key
```

### Ingress Configuration

File: `k8s/wisecow-ingress.yaml`

I created an Ingress resource with the following configuration:

- Hostname: `52.66.255.103.nip.io`
- TLS Secret: `wisecow-tls`
- Backend Service: `wisecow-service`
- Backend Port: `4499`

I configured the Ingress to route incoming HTTPS requests to the Wisecow Kubernetes Service.

### Apply Ingress Configuration

```bash
kubectl apply -f k8s/wisecow-ingress.yaml
```

### Verify Ingress and TLS Secret

I verified the Ingress Controller, Ingress resource, and TLS Secret using:

```bash
kubectl get ingress
kubectl get pods -n ingress-nginx
kubectl get services -n ingress-nginx
kubectl get secrets
```

### Application HTTPS URL

I successfully accessed my Wisecow application using:

https://52.66.255.103.nip.io:32177

**Note:**

- I used a self-signed certificate, so the browser may display a security warning.
- HTTPS encryption is enabled, but my certificate is not trusted by public certificate authorities.
- I used nip.io DNS with my EC2 public IP.
- If my EC2 public IP changes, I need to update the hostname, certificate, and Ingress configuration.
- I configured the EC2 Security Group to allow the required NodePort traffic.

---

# Problem Statement 2: Bash Scripting

For the second problem statement, I selected and implemented the following two tasks using Bash scripting:

1. System Health Monitoring Script.
2. Application Health Checker.

## 1. System Health Monitoring Script

File: `scripts/system-health-monitor.sh`

### Objective

I developed a Bash script to monitor important Linux system resources and generate alerts whenever resource usage exceeds predefined thresholds.

### Metrics Monitored

**CPU Usage**

I used `vmstat` to calculate CPU utilization.

**Memory Usage**

I used the `free` command to calculate memory utilization.

**Disk Usage**

I used the `df` command to check root filesystem disk utilization.

**Running Processes**

I used `ps` to count the currently running processes.

### Alert Thresholds

| Metric | Threshold |
|---|---:|
| CPU Usage | 80% |
| Memory Usage | 80% |
| Disk Usage | 80% |
| Running Processes | 250 |

I configured the script to display an alert when a metric exceeds its threshold. Otherwise, it displays an OK status.

### Execute the Script

I made the script executable and ran it using:

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

- I implemented CPU utilization monitoring.
- I implemented memory utilization monitoring.
- I implemented disk utilization monitoring.
- I added running process counting.
- I configured threshold-based alerts.
- I included the monitoring date and time in the output.

## 2. Application Health Checker

File: `scripts/application-health-checker.sh`

### Objective

I developed a Bash script to check the availability of my deployed Wisecow application using HTTPS requests and HTTP response status codes.

### Working

I used `curl` to send an HTTPS request to my deployed application.

The script checks the HTTP response status code:

- HTTP 200 – Application is UP.
- Any other response or connection failure – Application is DOWN.

### Execute the Script

I made the script executable and ran it using:

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

- I implemented application availability checking.
- I used HTTPS for communication.
- I validated HTTP response status codes.
- I configured the script to follow redirects.
- I added connection and request timeouts.
- I configured it to display the application status as UP or DOWN.

**Note:** In this project, I used the EC2 private IP with the `curl --resolve` option to check the application. I also used `-k` because I configured a self-signed TLS certificate. If my EC2 IP address changes, I need to update the IP and hostname in the script. These configurations are used for this practice project.

---

# Repository Structure

I organized my project files as follows:

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

During implementation, I followed these security practices:

- I stored Docker Hub credentials using GitHub Actions Secrets.
- I did not commit my Kubernetes kubeconfig to the GitHub repository.
- I did not commit TLS private key and certificate files to the repository.
- I configured the self-hosted GitHub Actions runner for my assessment repository.
- I used a self-signed TLS certificate for this practice environment.
- I allowed the required inbound traffic through the EC2 Security Group.

# Conclusion

Through this assessment, I successfully containerized the Wisecow application using Docker and deployed it on Kubernetes.

I implemented CI/CD automation using GitHub Actions to build and push Docker images to Docker Hub and automatically deploy updated images to Kubernetes.

I also configured NGINX Ingress and TLS to enable HTTPS access to the application.

For the second problem statement, I developed two Bash scripts to monitor Linux system resources and check application availability.

This practical implementation helped me gain hands-on experience with Docker, Kubernetes, AWS EC2, GitHub Actions, CI/CD, TLS configuration, and Linux Bash scripting.

