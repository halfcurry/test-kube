# 1. Delete any existing Kind cluster to ensure a clean setup for new config
kind delete cluster --name k8s-poc-cluster || true # Use || true to ignore errors if cluster doesn't exist

# 2. Create Kind cluster (no special registry config needed with kind load)
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: k8s-poc-cluster
nodes:
# The control-plane node will have the Ingress-ready label
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  # Forward HTTP and HTTPS ports for Ingress
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
# Worker nodes
- role: worker
- role: worker
EOF