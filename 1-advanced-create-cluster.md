## Advanced Cluster Setup with a Config File

Instead of using the simple `kind create cluster` command, we will now define our cluster's structure in a YAML configuration file. This gives us precise control over the number of nodes, port mappings, and other advanced settings. This is standard practice for any non-trivial local development.

### The Goal

Our goal is to create a 3-node Kubernetes cluster (1 control-plane node and 2 worker nodes). We will also map ports `80` and `443` from our Codespace environment to the control-plane node. This is essential for a later step when we install an Ingress controller, which acts as the entry point for web traffic into our cluster.

### 1. The `kind` Configuration File

First, create a file named `kind-config.yaml`. This file tells `kind` exactly what kind of cluster we want.

```yaml
# kind-config.yaml

# kind specifies the type of Kind object, in this case, a Cluster.
kind: Cluster
# apiVersion is the version of the Kind configuration API.
apiVersion: kind.x-k8s.io/v1alpha4
# name provides a name for your cluster.
name: k8s-poc-cluster

# 'nodes' is a list of nodes to create for the cluster.
nodes:
# The first node is designated as the control-plane. It runs the main
# Kubernetes components like the API server and scheduler.
- role: control-plane
  # kubeadmConfigPatches allows us to inject custom configuration into the node.
  # We are using it here to add a label to our node.
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        # We add a label "ingress-ready=true" to this node. This is a common
        # practice to signal that an Ingress controller should be scheduled
        # to run on this specific node.
        node-labels: "ingress-ready=true"
  # extraPortMappings is one of the most important sections for local development.
  # It maps ports from the host (your Codespace) to the Kind "node" (a Docker container).
  # This makes services inside the cluster accessible from your local machine.
  extraPortMappings:
  # Map port 80 on the host to port 80 on the control-plane node container.
  # This is for standard HTTP traffic.
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  # Map port 443 on the host to port 443 on the control-plane node container.
  # This is for secure HTTPS traffic.
  - containerPort: 443
    hostPort: 443
    protocol: TCP

# These nodes are designated as 'workers'. Their primary job is to run
# the actual application Pods you deploy.
- role: worker
- role: worker
```

### 2. The Setup Script

Now, let's create a small shell script to automate the cluster creation process using our new configuration file. Create a file named `setup-cluster.sh`.

```bash
#!/bin/bash
# setup-cluster.sh

# This script creates a Kind cluster using the specified configuration file.

# 'set -e' will cause the script to exit immediately if any command fails.
set -e

echo "🔥 Deleting any existing 'k8s-poc-cluster' to ensure a clean start..."
# It's good practice to delete any old cluster with the same name first.
# The '--silent' flag prevents errors if the cluster doesn't exist.
# The '--silent' flag was removed in newer Kind versions as this is now the default behavior.
kind delete cluster --name k8s-poc-cluster

echo "🚀 Creating a new multi-node Kind cluster with ingress-ready port mappings..."
# We now point the 'kind create cluster' command to our config file.
kind create cluster --config kind-config.yaml

echo "✅ Cluster 'k8s-poc-cluster' created successfully!"
echo "👉 You can now check the nodes with: kubectl get nodes"
```

### 3. How to Run It

1.  Make the script executable:
    `chmod +x setup-cluster.sh`

2.  Run the script:
    `sh ./setup-cluster.sh`

After the script finishes, you will have a new, more robust Kubernetes cluster. You can verify this by running `kubectl get nodes`. You will now see three nodes listed: one `control-plane` and two `worker` nodes.
