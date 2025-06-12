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