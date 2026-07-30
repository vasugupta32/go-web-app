Install Argo CD on Kubernetes (EKS)

Argo CD is a GitOps continuous delivery tool for Kubernetes that automatically deploys applications from Git repositories.

📦 Step 1: Create Argo CD Namespace
kubectl create namespace argocd

🚀 Step 2: Install Argo CD Using Official Manifests
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


This deploys all Argo CD components into the argocd namespace.

🌐 Step 3: Expose Argo CD Server Using LoadBalancer (Linux/macOS)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

🪟 Step 3 (Windows PowerShell)
kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'

📡 Step 4: Get the LoadBalancer Endpoint
kubectl get svc argocd-server -n argocd


Look for the EXTERNAL-IP (or AWS ELB DNS name) and open it in your browser using:

https://<external-ip-or-dns>


⚠ You may see a TLS warning — this is expected for the default Argo CD certificate.