Install Amazon EKS

Before starting, make sure you have completed all steps in the prerequisites document.

🚀 Create an EKS Cluster (Free-Tier Friendly)

For beginners and learners, it’s recommended to create a small managed node group to minimize AWS costs:

eksctl create cluster \
  --name demo-cluster \
  --region us-east-1 \
  --nodes 1 \
  --node-type t3.small \
  --managed

Why these options?

--nodes 1 → creates only one worker node to reduce cost

--node-type t3.small → eligible for AWS Free Tier

--managed → AWS manages the node group for easier maintenance

This setup is ideal for testing, learning, and small demos.

🗑 Delete the EKS Cluster (Important to avoid charges)

When you’re finished, delete the cluster to prevent ongoing AWS costs:

eksctl delete cluster \
  --name demo-cluster \
  --region us-east-1

