# Building a Complete CI/CD Pipeline for a Go Web App: From Code to Kubernetes in 3 Minutes

*A hands-on, beginner-friendly guide to Docker, Kubernetes, Helm, GitHub Actions, AWS EKS, and ArgoCD*

**By Vasu Gupta** | [GitHub](https://github.com/vasugupta32) | [LinkedIn](https://www.linkedin.com/in/vasugupta32/)

**Repository:** [github.com/vasugupta32/go-web-app](https://github.com/vasugupta32/go-web-app)

**Also published on Medium:** [Building a Complete CI/CD Pipeline for a Go Web App](https://medium.com/@vasugupt32/building-a-complete-ci-cd-pipeline-for-a-go-web-app-from-code-to-kubernetes-in-3-minutes-033340704f4d)

---

## TL;DR

In this tutorial you will build a complete DevOps pipeline for a Go web application:

1. Write a simple Go web server
2. Containerize it with a multi-stage Dockerfile
3. Create a Kubernetes cluster on AWS EKS
4. Package the app with Helm
5. Install NGINX Ingress Controller
6. Automate builds and image pushes with GitHub Actions
7. Deploy automatically using ArgoCD (GitOps)

After setup, **every `git push` automatically triggers a build, creates a Docker image, and deploys it to Kubernetes — in under 3 minutes.**

---

## Architecture Overview

Before we start building, here is the full picture of what we are creating:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              Developer                                   │
│                          git push → main                                 │
└─────────────────────────────┬────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                                │
│                                                                          │
│   ┌────────────────────────────────────────────────────────────────┐     │
│   │              GitHub Actions CI Pipeline                        │     │
│   │                                                                │     │
│   │  [build & test] → [lint] → [docker build+push] → [update tag] │     │
│   └────────────────────────────────────────────────────────────────┘     │
│                                           │                              │
│                             updates values.yaml                          │
│                             (new image tag)                              │
└───────────────────────────────────────────┬──────────────────────────────┘
                                            │
                                            │ ArgoCD polls every 3 min
                                            ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                           AWS EKS Cluster                                │
│                                                                          │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐   │
│   │    ArgoCD    │───▶│  Helm Chart  │───▶│   Go Web App Pods        │   │
│   │  (GitOps CD) │    │  (templated  │    │   (Deployment)           │   │
│   │              │    │   manifests) │    │                          │   │
│   └──────────────┘    └──────────────┘    └──────────────────────────┘   │
│                                                         ▲                │
│   ┌──────────────────────────────────────────────────────────────┐        │
│   │              NGINX Ingress Controller                         │        │
│   │     (routes external traffic → pods via ClusterIP service)   │        │
│   └──────────────────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────────────────┘
                              ▲
                              │ HTTP
                         [ Internet ]
```

**Data flow on every commit:**
```
Developer pushes code
  → GitHub Actions: test → lint → build image → push to Docker Hub
  → GitHub Actions: commits updated image tag back to repo
  → ArgoCD: detects values.yaml change → deploys new pods to EKS
  → Zero-downtime rolling update complete
```

---

## Prerequisites

You need the following tools installed before starting. This section gives you exact commands.

### 1. Go (1.22+)

```bash
# macOS
brew install go

# Ubuntu/Debian
sudo apt-get install golang-go

# Verify
go version
# go version go1.22.5 darwin/arm64
```

### 2. Docker Desktop

Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop).

```bash
# Verify
docker --version
# Docker version 26.1.1
```

### 3. kubectl

```bash
# macOS
brew install kubectl

# Ubuntu/Debian
sudo apt-get install kubectl

# Verify
kubectl version --client
```

### 4. AWS CLI

```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version
# aws-cli/2.x.x

# Configure with your AWS credentials
aws configure
# AWS Access Key ID: <your-key>
# AWS Secret Access Key: <your-secret>
# Default region name: us-east-1
# Default output format: json
```

> **Where to get AWS credentials:** AWS Console → IAM → Users → Your user → Security credentials → Create access key.

### 5. eksctl

```bash
# macOS
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Linux
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"
tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify
eksctl version
```

### 6. Helm

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

### 7. Accounts you need

- **GitHub account** — to host the code and run GitHub Actions
- **Docker Hub account** — to store Docker images (free tier is fine)
- **AWS account** — to run EKS (this will cost ~$2–3/day; delete the cluster when done)

---

## Part 1: The Go Web Application

### What we are building

A simple portfolio website with four pages (Home, About, Contact, Projects) and a health check endpoint. This could be any Go web app — the pipeline works the same way.

### Project structure

```
go-web-app/
├── main.go                        # Application entry point
├── main_test.go                   # Unit tests
├── go.mod                         # Go module definition
├── Dockerfile                     # Multi-stage Docker build
├── static/                        # HTML pages served by the app
│   ├── home.html
│   ├── about.html
│   ├── contact.html
│   └── courses.html
├── .github/
│   └── workflows/
│       └── cicd.yaml              # GitHub Actions CI/CD workflow
├── helm/
│   └── go-web-app-chart/          # Helm chart for Kubernetes deployment
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── ingress.yaml
├── k8s/
│   └── manifests/                 # Raw Kubernetes manifests (reference)
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
├── eks/                           # EKS setup guides
├── gitops/argocd/                 # ArgoCD installation guide
└── ingress-controller/nginx/      # NGINX ingress setup guide
```

### The application code

**`main.go`** — routes each URL to an HTML file and exposes a `/health` endpoint that Kubernetes uses to check if the pod is alive:

```go
package main

import (
    "log"
    "net/http"
)

func homePage(w http.ResponseWriter, r *http.Request) {
    http.ServeFile(w, r, "static/home.html")
}

func coursePage(w http.ResponseWriter, r *http.Request) {
    http.ServeFile(w, r, "static/courses.html")
}

func aboutPage(w http.ResponseWriter, r *http.Request) {
    http.ServeFile(w, r, "static/about.html")
}

func contactPage(w http.ResponseWriter, r *http.Request) {
    http.ServeFile(w, r, "static/contact.html")
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

func rootRedirect(w http.ResponseWriter, r *http.Request) {
    http.Redirect(w, r, "/home", http.StatusSeeOther)
}

func main() {
    http.HandleFunc("/", rootRedirect)
    http.HandleFunc("/home", homePage)
    http.HandleFunc("/courses", coursePage)
    http.HandleFunc("/about", aboutPage)
    http.HandleFunc("/contact", contactPage)
    http.HandleFunc("/health", healthCheck)

    log.Println("Server starting on port 8080...")
    log.Fatal(http.ListenAndServe("0.0.0.0:8080", nil))
}
```

**`go.mod`** — declares the module name:

```
module github.com/vasugupta32/go-web-app

go 1.22.5
```

**`main_test.go`** — a unit test for the home page handler:

```go
package main

import (
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestMain(t *testing.T) {
    req, _ := http.NewRequest("GET", "/home", nil)
    rr := httptest.NewRecorder()
    http.HandlerFunc(homePage).ServeHTTP(rr, req)

    if rr.Code != http.StatusOK {
        t.Errorf("expected 200, got %v", rr.Code)
    }
    if ct := rr.Header().Get("Content-Type"); ct != "text/html; charset=utf-8" {
        t.Errorf("expected text/html, got %v", ct)
    }
}
```

### Run it locally

```bash
git clone https://github.com/vasugupta32/go-web-app.git
cd go-web-app

# Run the app
go run main.go
# 2024/01/26 10:00:00 Server starting on port 8080...

# Open a new terminal and test
curl http://localhost:8080/health
# OK

# Open http://localhost:8080 in your browser
```

---

## Part 2: Containerizing with Docker

### Why Docker?

Without Docker, your app might work on your laptop (Go 1.22, specific OS libraries) but fail on a server with a different environment. Docker packages the app along with its exact runtime — the "it works on my machine" problem disappears.

### Understanding multi-stage builds

Our Dockerfile has two stages:

**Stage 1 — build** (`golang:1.22.5`, ~900MB): Compiles the Go binary using the full Go toolchain.

**Stage 2 — runtime** (`alpine:latest`, ~7MB): Runs the compiled binary. Only this stage ships.

We only ship the runtime stage. The final image is ~15MB instead of ~900MB. Smaller images pull faster and have a smaller attack surface.

**`Dockerfile`:**

```dockerfile
# ---------- Build Stage ----------
FROM golang:1.22.5 AS base

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main .

# ---------- Runtime Stage ----------
FROM alpine:latest

# ca-certificates is needed for HTTPS calls from the app
RUN apk add --no-cache ca-certificates

WORKDIR /app

COPY --from=base /app/main .
COPY --from=base /app/static ./static

EXPOSE 8080

CMD ["./main"]
```

**Build flags explained:**
- `CGO_ENABLED=0` — disables C bindings, creates a fully static binary (required for Alpine)
- `GOOS=linux` — cross-compiles for Linux even if you are on macOS
- `GOARCH=amd64` — targets x86-64 architecture

### Build and test locally

```bash
# Replace 'vasugupta32' with your Docker Hub username throughout
docker build -t vasugupta32/go-web-app:v1 .

# Expected output (last few lines):
# => exporting to image
# => => writing image sha256:abc123...
# => => naming to docker.io/vasugupta32/go-web-app:v1

# Run the container
docker run -d -p 8080:8080 --name go-app vasugupta32/go-web-app:v1

# Test the health endpoint
curl http://localhost:8080/health
# OK

# Check image size — should be around 15MB
docker images vasugupta32/go-web-app
# REPOSITORY                TAG   IMAGE ID       SIZE
# vasugupta32/go-web-app    v1    abc123def456   15.2MB

# Stop and remove the container
docker stop go-app && docker rm go-app
```

### Push to Docker Hub

You need a Docker Hub account and an access token (not your password).

**Step 1:** Log in at [hub.docker.com](https://hub.docker.com) and create a repository named `go-web-app`.

**Step 2:** Create an access token:
- Docker Hub → Account Settings → Security → New Access Token
- Give it a name (e.g., `github-actions`) and **Read, Write, Delete** permission
- Copy the token — you will not see it again

**Step 3:** Log in from your terminal:

```bash
docker login
# Username: vasugupta32
# Password: <your-access-token>
# Login Succeeded
```

**Step 4:** Push the image:

```bash
docker push vasugupta32/go-web-app:v1
# The push refers to repository [docker.io/vasugupta32/go-web-app]
# v1: digest: sha256:... size: 1234
```

---

## Part 3: Creating an EKS Cluster

### Why EKS instead of running Kubernetes yourself?

Kubernetes has two components:
- **Control plane** (API server, scheduler, etcd) — brain of the cluster
- **Worker nodes** — where your containers actually run

Running the control plane yourself is complex (high availability, certificates, upgrades). AWS EKS manages the control plane for you. You only manage the worker nodes.

### Cost warning

EKS is **not free**. A `t3.medium` node costs approximately $0.10/hour (~$2.40/day). The EKS control plane itself costs $0.10/hour.

**Total: ~$4–5/day** while the cluster is running. Delete it when you are done with this tutorial.

### Step 1: Create the cluster

```bash
eksctl create cluster \
  --name demo-cluster \
  --region us-east-1 \
  --nodes 1 \
  --node-type t3.medium \
  --managed
```

This takes **15–20 minutes**. Go make a coffee.

**What this command creates:**
- VPC with public and private subnets across two availability zones
- EKS control plane (managed by AWS)
- One `t3.medium` EC2 worker node
- IAM roles for the node and the cluster
- kubeconfig entry so kubectl can connect

> **Why t3.medium and not t3.small?**
> When you run ArgoCD, NGINX Ingress, and your app pods simultaneously, `t3.small` (2 vCPU, 2GB RAM) quickly runs out of memory. ArgoCD alone needs ~500MB. `t3.medium` (2 vCPU, 4GB RAM) handles everything comfortably.

**Expected output (end of creation):**

```
✓  EKS cluster "demo-cluster" in "us-east-1" region is ready
```

### Step 2: Verify the connection

```bash
kubectl get nodes
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-192-168-xx-xx.ec2.internal Ready    <none>   2m    v1.30.x
```

If you see `Ready`, your cluster is working.

---

## Part 4: Kubernetes Manifests

Before using Helm, let's understand what Kubernetes objects we need by looking at the raw manifests in `k8s/manifests/`.

### Deployment — runs your pods

```yaml
# k8s/manifests/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-web-app
  labels:
    app: go-web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: go-web-app
  template:
    metadata:
      labels:
        app: go-web-app
    spec:
      containers:
        - name: go-web-app
          image: vasugupta32/go-web-app:v3
          ports:
            - containerPort: 8080
```

**Key fields:**
- `replicas: 1` — run one pod (for production you would set this to 3+)
- `selector.matchLabels` — the Deployment manages any pod with `app: go-web-app`
- `template` — the blueprint for each pod

### Service — stable network endpoint inside the cluster

```yaml
# k8s/manifests/service.yaml (also in helm/go-web-app-chart/templates/service.yaml)
apiVersion: v1
kind: Service
metadata:
  name: go-web-app
  labels:
    app: go-web-app
spec:
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
  selector:
    app: go-web-app
  type: ClusterIP
```

**Why ClusterIP and not LoadBalancer?**
`ClusterIP` makes the service reachable only inside the cluster. The Ingress controller (which gets its own LoadBalancer) then routes external traffic to this service. This approach uses one load balancer for all services instead of one per service — much cheaper.

### Ingress — routes external HTTP traffic

```yaml
# k8s/manifests/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: go-web-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: go-web-app.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: go-web-app
                port:
                  number: 80
```

**How Ingress works:**

```
Internet → AWS Load Balancer → NGINX Ingress Controller Pod → Service → App Pods
```

The NGINX Ingress Controller (installed in the next section) reads Ingress resources and configures NGINX to route traffic accordingly.

---

## Part 5: Helm — Packaging Kubernetes Manifests

### The problem with raw YAML

As your application grows, you accumulate many YAML files. Every environment (dev, staging, production) needs slightly different values (image tag, replica count, hostname). Managing this by editing files manually is error-prone.

Helm solves this with **templating**. You define one chart and override values per environment.

### The Helm chart structure

```
helm/go-web-app-chart/
├── Chart.yaml           # Chart metadata (name, version)
├── values.yaml          # Default values for the templates
└── templates/
    ├── deployment.yaml  # Same as k8s/manifests but uses {{ .Values.* }}
    ├── service.yaml
    └── ingress.yaml
```

**`Chart.yaml`** — metadata about the chart:

```yaml
apiVersion: v2
name: go-web-app-chart
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "1.0.0"
```

**`values.yaml`** — the single file you edit to change the deployment:

```yaml
replicaCount: 1

image:
  repository: vasugupta32/go-web-app
  pullPolicy: IfNotPresent
  tag: "21365114295"     # GitHub Actions will auto-update this

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
```

**`templates/deployment.yaml`** — notice the `{{ .Values.image.tag }}` placeholder:

```yaml
spec:
  containers:
    - name: go-web-app
      image: vasugupta32/go-web-app:{{ .Values.image.tag }}
      ports:
        - containerPort: 8080
```

When GitHub Actions runs `sed -i 's/tag: .*/tag: "${{ github.run_id }}"/' helm/go-web-app-chart/values.yaml`, it updates `values.yaml` with the new image tag. ArgoCD then picks up this change and redeploys. **This is the core of the GitOps loop.**

### Install the app with Helm (manual test)

```bash
# From the repo root
helm install go-web-app ./helm/go-web-app-chart

# Expected output:
# NAME: go-web-app
# LAST DEPLOYED: Mon Jan 27 10:00:00 2025
# NAMESPACE: default
# STATUS: deployed

# Verify
kubectl get pods
# NAME                          READY   STATUS    RESTARTS   AGE
# go-web-app-7d6f8c9b4-xk2pq   1/1     Running   0          30s

# Uninstall (we will let ArgoCD manage this from now on)
helm uninstall go-web-app
```

---

## Part 6: NGINX Ingress Controller

### Why do you need an Ingress Controller?

An Ingress resource (from Part 4) is just a specification — it says "route traffic for host X to service Y". It does nothing on its own. You need an **Ingress Controller** that reads those specs and actually does the routing.

We use the NGINX Ingress Controller. It runs as a pod in the cluster and creates an AWS Network Load Balancer to receive external traffic.

### Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/aws/deploy.yaml
```

**What this creates:**
- `ingress-nginx` namespace
- NGINX controller Deployment
- `ingress-nginx-controller` Service of type `LoadBalancer` (provisions an AWS NLB)
- ClusterRole, ServiceAccount, ConfigMaps, etc.

### Wait for the LoadBalancer to provision

```bash
kubectl get svc -n ingress-nginx
# NAME                       TYPE           CLUSTER-IP    EXTERNAL-IP                                     PORT(S)
# ingress-nginx-controller   LoadBalancer   10.100.x.x    a1b2c3d4-xxxx.us-east-1.elb.amazonaws.com      80:xxxxx/TCP
```

The `EXTERNAL-IP` will change from `<pending>` to an AWS ELB DNS name in about 2–3 minutes.

> **Keep this DNS name handy.** This is the address you will use to access your application.

---

## Part 7: GitHub Actions — The CI Pipeline

### What the pipeline does

Every time you push to `main`, GitHub Actions automatically:

1. **Builds and tests** the Go application
2. **Lints** the code with GolangCI-Lint
3. **Builds** a Docker image tagged with `${{ github.run_id }}`
4. **Pushes** the image to Docker Hub
5. **Updates** `helm/go-web-app-chart/values.yaml` with the new tag and commits it back

**Why `github.run_id` as the image tag?**
It is a monotonically increasing integer (e.g., `8734219`). It is unique per workflow run, sequential, and easy to correlate with a GitHub Actions run. You can look at the tag on Docker Hub and immediately find the corresponding GitHub Actions run.

### The workflow file

**`.github/workflows/cicd.yaml`:**

```yaml
name: CI/CD

# Trigger on push to main.
# Ignore changes to Helm charts — otherwise updating values.yaml would
# trigger another pipeline, creating an infinite loop.
on:
  push:
    branches:
      - main
    paths-ignore:
      - helm/**
      - k8s/**
      - README.md

jobs:

  # ── Job 1: Build and test the Go application ─────────────────────────────
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v2
        with:
          go-version: 1.22

      - name: Build
        run: go build -o go-web-app

      - name: Test
        run: go test ./...

  # ── Job 2: Lint ───────────────────────────────────────────────────────────
  code-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: GolangCI-Lint
        uses: golangci/golangci-lint-action@v6
        with:
          version: latest

  # ── Job 3: Build and push Docker image ───────────────────────────────────
  push:
    runs-on: ubuntu-latest
    needs: build          # Only runs if the build job succeeds
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/go-web-app:${{ github.run_id }}

  # ── Job 4: Update the image tag in the Helm chart (GitOps trigger) ───────
  update-newtag-in-helm-chart:
    runs-on: ubuntu-latest
    needs: push           # Only runs if docker push succeeded
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.TOKEN }}   # Needs write access to commit back

      - name: Update image tag
        run: |
          sed -i 's/tag: .*/tag: "${{ github.run_id }}"/' helm/go-web-app-chart/values.yaml

      - name: Commit and push Helm chart update
        run: |
          git config --global user.email "vasugupt32@gmail.com"
          git config --global user.name "Vasu Gupta"
          git add helm/go-web-app-chart/values.yaml
          git commit -m "Update Docker image tag in Helm chart"
          git push
```

### Setting up GitHub Secrets

The workflow uses three secrets. You must add these before the pipeline will work.

**Navigate to:** Your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

**`DOCKERHUB_USERNAME`** — Your Docker Hub username (e.g. `vasugupta32`). Find it on your Docker Hub profile page.

**`DOCKERHUB_TOKEN`** — A Docker Hub access token (not your password). Create one at Docker Hub → Account Settings → Security → New Access Token. Give it Read, Write, Delete permissions.

**`TOKEN`** — A GitHub Personal Access Token. Create one at GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token. Select the `repo` scope.

**For the GitHub `TOKEN`:**
- Go to [github.com/settings/tokens](https://github.com/settings/tokens)
- Click **Generate new token (classic)**
- Set expiration (90 days is fine for learning)
- Check the `repo` scope (full control of private repositories)
- Click **Generate token** and copy it immediately

> **Why do you need a Personal Access Token and not just `GITHUB_TOKEN`?**
> The built-in `GITHUB_TOKEN` intentionally cannot trigger other workflow runs. If it committed back to the repo, that new commit would need to trigger ArgoCD to deploy — and ArgoCD monitors the Git repo. The Personal Access Token allows the commit from GitHub Actions to be recognized by ArgoCD as a real change.

### Testing the CI pipeline

```bash
# Make a small change to trigger the pipeline
# (don't change files in helm/**, k8s/**, or README.md — those are ignored)
echo "" >> main.go
git add main.go
git commit -m "Trigger CI pipeline test"
git push origin main
```

Go to **GitHub → your repo → Actions tab**. You will see a new workflow run. Click on it to see the jobs.

**Expected result after ~3 minutes:**

```
✅ build           (30s)  — go build + go test pass
✅ code-quality    (45s)  — GolangCI-Lint passes
✅ push            (90s)  — Docker image pushed as vasugupta32/go-web-app:8734219
✅ update-newtag   (10s)  — values.yaml updated and committed
```

Check your repository — you will see a new commit from GitHub Actions:
```
Update Docker image tag in Helm chart
```

And `helm/go-web-app-chart/values.yaml` will now contain:
```yaml
  tag: "8734219"
```

---

## Part 8: ArgoCD — GitOps Continuous Delivery

### The GitOps concept

**Traditional CD (push model):** Your CI server builds the image and then SSH's into the server or calls the Kubernetes API to deploy it. The cluster has no record of what should be running — it only knows what someone told it.

**GitOps (pull model):** Your Git repository is the single source of truth. The Kubernetes cluster has an agent (ArgoCD) that continuously polls the Git repo and applies any difference it finds between the desired state (Git) and the actual state (cluster).

```
Pull model benefits:
  • Rollback = git revert
  • Audit trail = git log
  • Disaster recovery = re-apply from Git
  • Security = cluster pulls; no external push access needed
```

### Step 1: Install ArgoCD

```bash
# Create dedicated namespace
kubectl create namespace argocd

# Install ArgoCD (official manifest)
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait until all pods are Running
kubectl get pods -n argocd -w
# NAME                                                READY   STATUS    RESTARTS
# argocd-server-5f8984b8bc-k2xpq                     1/1     Running   0
# argocd-repo-server-7d6db65b4b-np9qw                1/1     Running   0
# argocd-application-controller-0                    1/1     Running   0
# argocd-dex-server-7c9f8d6b4b-8xkpq                 1/1     Running   0
# argocd-redis-76b6d4b7b7-hpkqx                      1/1     Running   0
# Press Ctrl+C when all show 1/1 Running
```

### Step 2: Expose the ArgoCD UI

```bash
# Linux/macOS
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'

# Windows PowerShell
kubectl patch svc argocd-server -n argocd \
  -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'
```

```bash
# Get the external URL (wait ~2 min for EXTERNAL-IP to appear)
kubectl get svc argocd-server -n argocd
# NAME            TYPE           EXTERNAL-IP
# argocd-server   LoadBalancer   a9b8c7d6-xxxx.us-east-1.elb.amazonaws.com
```

### Step 3: Log in to ArgoCD

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 --decode
# Output: SomeRandomPassword123
```

Open `https://<EXTERNAL-IP>` in your browser.

> You will see a TLS certificate warning — this is expected because ArgoCD uses a self-signed certificate by default. Click **Advanced → Proceed**.

- **Username:** `admin`
- **Password:** (from the command above)

### Step 4: Create the ArgoCD Application

In the ArgoCD UI, click **+ NEW APP** and fill in the following fields:

- **Application Name:** `go-web-app`
- **Project:** `default`
- **Sync Policy:** `Automatic`
- **Self Heal:** `checked`
- **Repository URL:** `https://github.com/vasugupta32/go-web-app`
- **Revision:** `HEAD`
- **Path:** `helm/go-web-app-chart`
- **Cluster URL:** `https://kubernetes.default.svc`
- **Namespace:** `default`

Click **CREATE**.

**What ArgoCD does now:**
1. Clones your repository
2. Runs `helm template` on the chart with `values.yaml`
3. Applies the resulting Kubernetes manifests
4. Every 3 minutes (default), checks if Git matches the cluster
5. If different, automatically resyncs

> **Alternative: Create the app via YAML** (for GitOps purists)
>
> ```yaml
> # argocd-app.yaml
> apiVersion: argoproj.io/v1alpha1
> kind: Application
> metadata:
>   name: go-web-app
>   namespace: argocd
> spec:
>   project: default
>   source:
>     repoURL: https://github.com/vasugupta32/go-web-app
>     targetRevision: HEAD
>     path: helm/go-web-app-chart
>   destination:
>     server: https://kubernetes.default.svc
>     namespace: default
>   syncPolicy:
>     automated:
>       prune: true
>       selfHeal: true
> ```
> ```bash
> kubectl apply -f argocd-app.yaml
> ```

### Step 5: Verify the deployment

```bash
kubectl get pods
# NAME                               READY   STATUS    RESTARTS   AGE
# go-web-app-chart-7d6f8c9b4-xk2pq  1/1     Running   0          1m

kubectl get svc
# NAME              TYPE        CLUSTER-IP      PORT(S)
# go-web-app        ClusterIP   10.100.xx.xx    80/TCP

kubectl get ingress
# NAME         CLASS   HOSTS             ADDRESS
# go-web-app   nginx   go-web-app.local  a1b2c3d4.us-east-1.elb.amazonaws.com
```

---

## Part 9: End-to-End Test — The Full Loop

Now let's test the entire pipeline from code change to production.

### Step 1: Make a change

Edit `static/home.html` — change "Welcome to My Portfolio" to "Welcome to My Portfolio — v2":

```bash
# Open and edit the file
# Change: <h1>Welcome to My Portfolio</h1>
# To:     <h1>Welcome to My Portfolio — v2</h1>
```

### Step 2: Push

```bash
git add static/home.html
git commit -m "Update homepage heading to v2"
git push origin main
```

### Step 3: Watch GitHub Actions

Go to **GitHub → Actions**. You will see the workflow start within seconds.

```
Run #8734219
  ✅ build           ~30s
  ✅ code-quality    ~45s
  ✅ push            ~90s   → pushed vasugupta32/go-web-app:8734219
  ✅ update-newtag   ~10s   → committed tag update to values.yaml
```

### Step 4: Watch ArgoCD

In the ArgoCD UI, within 3 minutes you will see:

```
go-web-app   OutOfSync   Healthy    (Git has new values.yaml)
go-web-app   Syncing     Healthy    (Applying new Deployment)
go-web-app   Synced      Healthy    ✅
```

### Step 5: Verify in Kubernetes

```bash
# Watch pods — old one terminates, new one starts
kubectl get pods -w
# NAME                               READY   STATUS        RESTARTS
# go-web-app-chart-7d6f8c9b4-xk2pq   1/1     Terminating   0
# go-web-app-chart-9f8e7d6c5-ab3mn   1/1     Running       0

# Verify the new image tag is running
kubectl describe deployment go-web-app-chart | grep Image
# Image: vasugupta32/go-web-app:8734219

# Get the Ingress address
kubectl get ingress
# a1b2c3d4.us-east-1.elb.amazonaws.com
```

### Step 6: Access the app

```bash
# The Ingress is configured for host: go-web-app.local
# For testing, pass the Host header directly:
curl -H "Host: go-web-app.local" \
  http://a1b2c3d4.us-east-1.elb.amazonaws.com/health
# OK

curl -H "Host: go-web-app.local" \
  http://a1b2c3d4.us-east-1.elb.amazonaws.com/home
# <html>... Welcome to My Portfolio — v2 ...
```

**You changed one line of HTML, pushed it, and 3 minutes later the change is live in Kubernetes. Automatically. Every time.**

---

## Part 10: Cleanup (Important — Save Money)

When you are done, delete the AWS resources to stop incurring charges.

```bash
# Delete the EKS cluster (also deletes node groups, load balancers, etc.)
eksctl delete cluster \
  --name demo-cluster \
  --region us-east-1

# This takes 10-15 minutes.
# Expected output:
# ✓  deleted cluster "demo-cluster"
```

> Also check your AWS EC2 console and check for any lingering Load Balancers — occasionally `eksctl delete cluster` leaves them behind. If you see any, delete them manually under EC2 → Load Balancers.

---

## Lessons Learned and Common Pitfalls

### 1. The `paths-ignore` in the workflow is critical

```yaml
paths-ignore:
  - helm/**
  - k8s/**
```

Without this, when the pipeline commits the updated `values.yaml` back to the repo, it would trigger another pipeline run... which would commit another `values.yaml`... infinite loop. This `paths-ignore` prevents that by ignoring commits that only touch Helm/k8s files.

### 2. Use `t3.medium`, not `t3.small` for EKS

`t3.small` has 2GB RAM. ArgoCD alone uses ~500MB. NGINX Ingress uses ~200MB. Your app uses ~30MB. The kube-system pods use ~500MB. You will run out of memory and pods will be evicted. Use `t3.medium`.

### 3. The Personal Access Token needs `repo` scope

The built-in `GITHUB_TOKEN` cannot trigger new workflow runs (by design — it prevents loops). Your PAT with `repo` scope can commit back and ArgoCD treats it as a real change to watch.

### 4. Docker Hub token, not password

Docker Hub passwords cannot be used in GitHub Actions. Create a dedicated Access Token with Read/Write/Delete permissions under Docker Hub → Account Settings → Security.

### 5. Ingress requires the Controller to be installed first

Creating an Ingress resource without the NGINX Ingress Controller running does nothing. The Controller is what reads Ingress resources and configures routing. Always install the controller before creating Ingress objects.

### 6. ArgoCD self-signed certificate

The ArgoCD UI uses HTTPS with a self-signed cert. You will get a browser warning. This is expected. For production, configure cert-manager with Let's Encrypt.

---

## What the Complete Pipeline Looks Like

```
Code change
     │
     ▼ git push
GitHub Actions (CI)
     │
     ├─ go build ✓
     ├─ go test ✓
     ├─ golangci-lint ✓
     ├─ docker build + push → vasugupta32/go-web-app:8734219
     └─ git commit: update values.yaml tag → "8734219"
          │
          ▼ (3 min polling)
ArgoCD (CD)
     │
     ├─ detects values.yaml changed
     ├─ helm template → new Deployment manifest
     └─ kubectl apply → rolling update on EKS
          │
          ▼
Kubernetes Rolling Update
     ├─ new pod starts (go-web-app:8734219)
     ├─ readiness check passes
     ├─ old pod terminates
     └─ zero downtime ✅
```

**Total time from `git push` to live: 3–4 minutes.**

---

## What to Build Next

You now have a solid foundation. Here is what to add:

### Health probes (highly recommended)

Add liveness and readiness probes to `helm/go-web-app-chart/templates/deployment.yaml`:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

This ensures Kubernetes only sends traffic to pods that are actually healthy.

### Resource limits

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

Without limits, a misbehaving pod can consume all node resources.

### Monitoring with Prometheus + Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack
```

### Automatic HTTPS with cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --set installCRDs=true
```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: go-web-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: go-web-app-chart
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

---

## Summary

Here is everything you built, step by step:

**Step 1 — Go web server with `/health` endpoint**
Kubernetes needs a health endpoint to know when a pod is ready to receive traffic and when to restart it.

**Step 2 — Multi-stage Dockerfile**
The final image is ~15MB instead of ~900MB. Smaller images pull faster and have a smaller attack surface.

**Step 3 — Push image to Docker Hub**
Kubernetes needs a container registry to pull images from. Docker Hub is free for public images.

**Step 4 — EKS cluster with `eksctl`**
AWS manages the Kubernetes control plane. You only manage the worker nodes.

**Step 5 — Deployment, Service, and Ingress manifests**
These are the three Kubernetes objects that run, expose, and route traffic to your application.

**Step 6 — Helm chart**
Templates the manifests so the image tag is a variable. This is what allows GitHub Actions to trigger a new deployment by changing one line.

**Step 7 — NGINX Ingress Controller**
Routes all external traffic through a single AWS load balancer instead of one per service.

**Step 8 — GitHub Actions CI pipeline**
Automatically builds, tests, lints, pushes the Docker image, and updates the Helm chart on every commit.

**Step 9 — ArgoCD GitOps CD**
Watches the Git repository. When `values.yaml` changes, it deploys the new image to Kubernetes automatically.

**Step 10 — End-to-end test**
One `git push` → 3 minutes → the change is live in Kubernetes with zero manual steps.

The key insight: **GitHub Actions writes the Docker image tag into Git. ArgoCD reads it from Git. Git is the single source of truth.**

---

## Get the Complete Code

All files from this tutorial are in the repository:

```bash
git clone https://github.com/vasugupta32/go-web-app.git
cd go-web-app
```

**What is included:**
- `main.go` + `main_test.go` — Go application and tests
- `Dockerfile` — multi-stage build
- `k8s/manifests/` — raw Kubernetes manifests
- `helm/go-web-app-chart/` — Helm chart
- `.github/workflows/cicd.yaml` — full GitHub Actions pipeline
- `eks/` — EKS setup commands
- `gitops/argocd/` — ArgoCD installation guide
- `ingress-controller/nginx/` — NGINX setup guide

---

## About the Author

**Vasu Gupta** — DevOps Engineer passionate about cloud infrastructure and automation.

- GitHub: [@vasugupta32](https://github.com/vasugupta32)
- LinkedIn: [vasugupta32](https://www.linkedin.com/in/vasugupta32/)

If this helped you, star the repo and share it. Questions? Open an issue or find me on LinkedIn.

---

## Quick Reference

```bash
# Local development
go run main.go
go test ./...

# Docker
docker build -t vasugupta32/go-web-app:v1 .
docker run -p 8080:8080 vasugupta32/go-web-app:v1
docker push vasugupta32/go-web-app:v1

# EKS
eksctl create cluster --name demo-cluster --region us-east-1 --nodes 1 --node-type t3.medium --managed
eksctl delete cluster --name demo-cluster --region us-east-1

# Kubernetes
kubectl get pods
kubectl get svc
kubectl get ingress
kubectl logs -f <pod-name>
kubectl describe pod <pod-name>

# Helm
helm install go-web-app ./helm/go-web-app-chart
helm upgrade go-web-app ./helm/go-web-app-chart
helm rollback go-web-app 1
helm uninstall go-web-app

# ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
```
