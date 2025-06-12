## Kubernetes Tutorial: Step 0 - Creating Your `kind` Cluster

Before we can deploy any applications, we need a running Kubernetes cluster. We will use `kind` (Kubernetes in Docker) to create a local cluster that runs entirely within Docker containers in your Codespace.

### 1. Create the Cluster

In your Codespace terminal, run the following command. This tells `kind` to create a new Kubernetes cluster.

```sh
# The 'create cluster' command bootstraps a Kubernetes cluster.
# The '--name' flag gives our cluster a specific name, which is useful
# for managing multiple clusters. We'll call ours 'k8s-poc-cluster'.
kind create cluster --name k8s-poc-cluster
```

You will see output showing the various steps `kind` is taking, like pulling the node image, preparing the nodes, and starting the control plane. This may take a minute or two to complete.

### 2. Verify the Cluster

Once the `kind create cluster` command finishes, your cluster is running! `kind` also automatically configures `kubectl` (the Kubernetes command-line tool) to point to your new cluster.

You can verify that `kubectl` can communicate with the cluster by running this command:

```sh
# 'cluster-info' dumps a set of URLs for the master and services.
# This is a quick way to confirm that kubectl can reach the cluster.
kubectl cluster-info
```

You should see output indicating that the Kubernetes control plane is running.

### 3. Check the Cluster Nodes

A Kubernetes cluster is made up of "nodes," which are worker machines that run your applications. In `kind`, each node is actually a Docker container. You can see the nodes in your cluster with this command:

```sh
# 'get nodes' lists all the node objects in the cluster.
# For a default 'kind' cluster, you'll see one node with the 'control-plane' role.
kubectl get nodes
```

The output should look similar to this, showing one node ready to go:

```
NAME                         STATUS   ROLES           AGE     VERSION
k8s-poc-cluster-control-plane   Ready    control-plane   2m14s   v1.29.2
```

**Congratulations!** You now have a fully functional, single-node Kubernetes cluster running in your Codespace. The cluster is a self-contained environment, perfect for learning and testing.
