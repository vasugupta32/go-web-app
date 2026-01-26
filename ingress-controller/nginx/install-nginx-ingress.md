Install NGINX Ingress Controller on AWS (EKS)

The NGINX Ingress Controller manages external access to services running inside your Kubernetes cluster.

Step 1: Deploy the Ingress Controller Manifest

Run the following command to install the controller in your cluster:

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/aws/deploy.yaml


This will:

Create the required namespaces and resources
Deploy the NGINX Ingress Controller
Configure AWS-compatible networking components