Install Amazon EKS

Before starting, make sure you have completed all steps in the prerequisites document.

# Install Amazon EKS

Before starting, complete all steps in the prerequisites document.

---

## 🚀 Create an EKS Cluster (Recommended for DevOps Labs)

To run tools like ArgoCD, Ingress Controller, and CI/CD workloads reliably,
use a slightly larger instance type.

```bash
eksctl create cluster \
  --name demo-cluster \
  --region us-east-1 \
  --nodes 1 \
  --node-type t3.medium \
  --managed
✅ Why these options?
--nodes 1 → keeps cost low for learning environments

--node-type t3.medium → enough CPU, memory, and pod capacity for:

ArgoCD

NGINX Ingress

Sample applications

--managed → AWS handles node lifecycle and upgrades

ℹ️ Smaller instances like t3.small quickly hit pod limits and resource issues when running DevOps tools.

💰 Cost note (important)
t3.medium is not Free Tier, but typically costs only a few dollars per day and avoids constant cluster failures.

🗑 Delete the EKS Cluster (Always clean up)
To prevent unnecessary charges:

eksctl delete cluster \
  --name demo-cluster \
  --region us-east-1
📌 Optional: Free-tier only (not recommended for GitOps)
If you want to experiment with very small apps only:

--node-type t3.small
⚠️ Not suitable for ArgoCD or production-style setups.

