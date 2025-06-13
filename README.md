# Test Kube: Kubernetes Learning and Demo Environment

Welcome to `test-kube`! This repository serves as a comprehensive learning and demonstration environment for various Kubernetes concepts, built specifically for testing within a Codespaces Devcontainer. It's structured to guide you from foundational Kubernetes resources to more advanced deployments and real-world examples.

## Project Overview

This project provides:
* Pre-configured development environment (`.devcontainer`) for easy setup.
* Step-by-step markdown guides for understanding core Kubernetes concepts.
* YAML manifest examples for various Kubernetes resources.
* Two realistic demo applications (`demo-project-1` and `demo-project-2`) showcasing common architectural patterns.

## Getting Started

To begin, ensure you open this repository in a GitHub Codespace or a compatible Devcontainer environment. The `.devcontainer` configuration will set up all necessary tools (Docker, Kind, Kubectl).

Once your Codespace is ready, start from the `0-create-cluster.md` guide for initial cluster creation and environment verification.

### Guides and Concepts

The learning journey is structured through a series of markdown files, each focusing on a specific Kubernetes concept or setup aspect. It's recommended to go through them in order.

* **`0-create-cluster.md`**: Your starting point for setting up the Codespaces environment and initial Kind cluster.
* **`1-advanced-create-cluster.md`**: More advanced cluster creation options.
* **`2-namespaces.md`**: Understanding resource isolation and organization with Kubernetes Namespaces.
* **`3-pods-and-deployments.md`**: Deep dive into running your applications with Pods and managing them with Deployments.
    * Related YAMLs: `my-nginx-pod.yaml`, `my-nginx-deployment.yaml`, `apache-deployment.yaml`
* **`4-services.md`**: Exposing your applications within and outside the cluster using various Service types.
    * Related YAMLs: `nginx-clusterip-service.yaml`, `nginx-nodeport-service.yaml`, `nginx-loadbalancer-service.yaml`, `apache-clusterip-service.yaml`
* **`5-configmaps-and-secrets.md`**: Managing configuration and sensitive data.
    * Related YAMLs: `nginx-configmap.yaml`, `nginx-deployment-with-configmap.yaml`, `database-secret.yaml`, `app-deployment-with-secret.yaml`
* **`6-ingress.md`**: Routing external HTTP/S traffic to your services.
    * Related YAMLs: `my-app-ingress.yaml`
* **`7-realistic-demo-project-1.md`**: A hands-on walkthrough of a multi-service application with Nginx Ingress. This builds upon the core concepts.
    * Related YAMLs: `my-hostpath-app-deployment.yaml`, `my-app-with-pvc-deployment.yaml`, `my-pv.yaml`, `my-pvc.yaml`
* **`8-advanced-concepts.md`**: Explore more advanced Kubernetes features like Liveness/Readiness Probes, Horizontal Pod Autoscaling, Jobs, CronJobs, and DaemonSets.
* **`9-big-demo-project-2.md`**: A more complex, multi-component "chatbot" demo project integrating databases, messaging queues, and logging agents.

### Utility Files

The repository also contains various utility YAML files that are referenced and used within the markdown guides:

* **`kind-config.yaml`**: The base Kind cluster configuration file.
* **`overall-setup.md`**: Cheatsheet for step by step commands.

## Debugging

Refer to the `debugging.md` file for common issues and troubleshooting tips within this Kubernetes environment.

## Contributions and Feedback

Feel free to explore, experiment, and provide feedback!