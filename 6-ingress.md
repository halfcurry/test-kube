# Understanding Kubernetes Ingress

You've learned about Services, which expose your applications, but what if you have multiple services and want to expose them all under a single IP address with intelligent routing rules (e.g., based on hostname or path)? This is where **Ingress** comes into play.

**Ingress** is a Kubernetes API object that manages external access to the services in a cluster, typically HTTP. It provides HTTP and HTTPS routing to services based on rules defined in the Ingress resource.

## Why Use Ingress?

* **Single Entry Point:** Provides a single, external IP address (often associated with a cloud load balancer) through which all your applications are exposed. This simplifies external access compared to managing multiple `NodePort` or `LoadBalancer` Services.
* **Host-Based Routing:** Route traffic to different services based on the hostname requested (e.g., `app1.example.com` goes to Service A, `app2.example.com` goes to Service B).
* **Path-Based Routing:** Route traffic to different services based on the URL path (e.g., `example.com/api` goes to API Service, `example.com/blog` goes to Blog Service).
* **SSL/TLS Termination:** Handle SSL/TLS encryption/decryption at the edge of your cluster, simplifying certificate management for your applications.
* **Centralized Configuration:** All routing rules are defined in a single Ingress resource, making them easier to manage and update.

## Ingress vs. Service Types

* **`NodePort` Services:** Exposes a service on a specific port on *every* node. You get one IP address per node, and managing many services this way can be cumbersome.
* **`LoadBalancer` Services:** Provisions an external cloud load balancer for *each* service. This can become expensive and complex for many services.
* **Ingress:** Typically uses a *single* `LoadBalancer` (or `NodePort` in local setups) and an **Ingress Controller** to intelligently route traffic to multiple internal `ClusterIP` Services. It acts as a smart router.

## Ingress Components

To use Ingress, you need two main components:

1.  **Ingress Resource:** This is the Kubernetes API object where you define the routing rules (host, path, target service, etc.). This is what you create using YAML.
2.  **Ingress Controller:** This is an actual application (typically a Pod running in your cluster) that watches the Kubernetes API for Ingress resources. When it finds them, it configures a reverse proxy (like Nginx, HAProxy, Traefik, or a cloud provider's load balancer) to implement the defined routing rules. **Without an Ingress Controller, an Ingress resource does nothing.**

    * **For local Kind clusters:** You'll often use Nginx Ingress Controller or a similar solution that leverages `NodePort` or `HostPort` to expose itself externally.
    * **For cloud clusters:** Cloud providers often offer their own managed Ingress Controllers (e.g., GKE Ingress, AWS Load Balancer Controller).

## Example: Exposing Nginx and Apache Services via Ingress

Let's assume you have two Deployments and their corresponding `ClusterIP` Services in the `my-app-dev` namespace:

1.  **Nginx Service:** `nginx-clusterip` (targeting Pods with `app: nginx`)
2.  **Apache Service:** `apache-clusterip` (targeting Pods with `app: apache`)

First, let's define the Apache Deployment and Service.

**`apache-deployment.yaml`**

```yaml
# apache-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  namespace: my-app-dev
  labels:
    app: apache
spec:
  replicas: 2
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache-container
        image: httpd:latest # Using the official Apache HTTP Server image
        ports:
        - containerPort: 80 # Apache typically listens on port 80
```

**`apache-clusterip-service.yaml`**

```yaml
# apache-clusterip-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: apache-clusterip # Name of the Apache Service
  namespace: my-app-dev
spec:
  selector:
    app: apache       # Selects Pods with the label `app: apache`
  ports:
    - protocol: TCP
      port: 80        # The port on which the Service listens
      targetPort: 80  # The port on the Pod (Apache container)
  type: ClusterIP     # Exposes Apache internally within the cluster
```

**To create Apache resources:**

```bash
kubectl apply -f apache-deployment.yaml
kubectl apply -f apache-clusterip-service.yaml
```

(Ensure you also have `nginx-deployment` and `nginx-clusterip-service` from the previous examples running in `my-app-dev`.)

### Defining the Ingress Resource

Now, let's create an Ingress resource that routes traffic based on paths:

* `http://your-ingress-ip/nginx` will go to the `nginx-clusterip` Service.
* `http://your-ingress-ip/apache` will go to the `apache-clusterip` Service.

**`my-app-ingress.yaml`**

```yaml
# my-app-ingress.yaml
apiVersion: networking.k8s.io/v1 # Specifies the Kubernetes API version for Ingress
kind: Ingress # Defines the type of Kubernetes resource as an Ingress
metadata:
  name: my-app-ingress # The name of your Ingress resource.
  namespace: my-app-dev # Specifies the namespace where this Ingress will reside.
  annotations:
    # IMPORTANT: These annotations are specific to the Ingress Controller you are using.
    # For Nginx Ingress Controller, these might be common. Other controllers will have different annotations.
    # For example, if using Nginx Ingress Controller and you want to use regex paths:
    # nginx.ingress.kubernetes.io/use-regex: "true"
    # nginx.ingress.kubernetes.io/rewrite-target: /$2 # Example for path stripping if using regex
spec:
  # IngressClassName is required in Kubernetes 1.18+ for Ingress v1.
  # This links the Ingress resource to a specific Ingress Controller.
  # The value 'nginx' is common for the Nginx Ingress Controller.
  ingressClassName: nginx # Replace with the name of your Ingress Controller if different.
  rules: # Define the routing rules for incoming traffic.
  - http: # Rules for HTTP traffic.
      paths: # List of paths to match.
      - path: /nginx # Path for Nginx application
        pathType: Prefix # 'Prefix' means the path must start with '/nginx'.
                         # Other types: 'Exact' (exact match), 'ImplementationSpecific'
        backend: # Defines where to send the traffic.
          service:
            name: nginx-clusterip # The name of the target Service (must be a ClusterIP Service).
            port:
              number: 80 # The port of the target Service to send traffic to.
      - path: /apache # Path for Apache application
        pathType: Prefix
        backend:
          service:
            name: apache-clusterip # The name of the target Service.
            port:
              number: 80
  # You can also define host-based rules here, for example:
  # - host: example.com
  #   http:
  #     paths:
  #     - path: /
  #       pathType: Prefix
  #       backend:
  #         service:
  #           name: default-web-service
  #           port:
  #             number: 80
  # You can also add TLS configuration here for HTTPS:
  # tls:
  # - hosts:
  #   - myapp.example.com
  #   secretName: myapp-tls-secret # Secret containing the TLS certificate and key
```

**To create this Ingress:**

```bash
kubectl apply -f my-app-ingress.yaml
```

**To check the Ingress details:**

```bash
kubectl get ingress -n my-app-dev
kubectl describe ingress my-app-ingress -n my-app-dev
```

You'll notice an `ADDRESS` field in the `kubectl get ingress` output. This will be the IP address of your Ingress Controller (e.g., the external IP of the LoadBalancer Service provisioned by the Ingress Controller, or a Node IP if using NodePort exposure).

## Essential Step: Deploying an Ingress Controller

Remember, an Ingress resource needs an **Ingress Controller** to function. For a local Kind cluster, the Nginx Ingress Controller is a popular choice.

**Installation (Example for Nginx Ingress Controller):**

This is typically done by applying a set of YAML manifests. **Do NOT run this if you already have an Ingress Controller or if it's not needed for your environment.**

A common way to install the Nginx Ingress Controller is to use the manifests provided by Kubernetes:

```bash
# This command fetches and applies the manifests for the Nginx Ingress Controller.
# It creates a new namespace (ingress-nginx), a Deployment, Service, and other necessary resources.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml

# Note: The version 'controller-v1.8.1' might be outdated. Always check the latest recommended version
# on the official Nginx Ingress Controller GitHub repository or documentation.
```

After deploying the Ingress Controller, it might take a few moments for it to provision any external IP address (if applicable to your environment) or for its NodePort to become available.

Once the Ingress Controller is running and has an external IP/port, you can access your applications via `http://<Ingress-IP-or-Node-IP>:<Ingress-Port>/nginx` and `http://<Ingress-IP-or-Node-IP>:<Ingress-Port>/apache`.

## How to Forward the Port in Codespaces

You need to identify the NodePort that the Nginx Ingress Controller's Service is using and then forward that specific port from your Codespace to your local machine.

Here are the steps:

### Step 1: Find the Ingress Controller's NodePort
The Nginx Ingress Controller typically runs in its own namespace, usually ingress-nginx. You can find the NodePort assigned to its Service using kubectl:

```Bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Look at the PORT(S) column in the output. You'll likely see something like 80:3xxxx/TCP,443:3yyyy/TCP. The 3xxxx is the NodePort for HTTP traffic (port 80) and 3yyyy is for HTTPS traffic (port 443). Make a note of the HTTP NodePort (e.g., 30080).

### Step 2: Forward the NodePort in Codespaces
You have two main ways to forward this port in Codespaces:

Option A: Manual Port Forwarding (Temporary)
This is good for quick testing:

In your VS Code or Codespaces web interface, open the PORTS tab (usually at the bottom panel next to "TERMINAL" and "PROBLEMS").
Click on the "Add Port" button (or similar icon, often a plus sign).
Enter the NodePort you identified in Step 1 (e.g., 30080).
Codespaces will then forward this port from the container to a local URL (e.g., http://localhost:30080).

```Bash
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 --address 0.0.0.0
```

## Conclusion

Ingress provides a powerful and flexible way to manage external access to your services in Kubernetes. By centralizing routing rules and leveraging an Ingress Controller, you can efficiently expose multiple applications, handle SSL/TLS, and implement sophisticated traffic management within your cluster.