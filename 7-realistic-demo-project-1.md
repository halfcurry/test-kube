# Realistic Kubernetes POC: Multi-Service Application with Ingress

This document outlines a more complete, yet still foundational, Kubernetes Proof-of-Concept (POC) application. It demonstrates how different components interact to form a functional system, accessible via an Ingress.

## 1. Project Structure

We'll organize our application components within a dedicated Kubernetes **Namespace** for better isolation and management.

## 2. Backend Services (Python Flask)

We'll create two simple Python Flask web services:
* **`hello-service`**: Returns a "Hello" message.
* **`greet-service`**: Returns a "Greetings" message.

These services will get their messages from a **ConfigMap**, making the messages configurable without changing the Docker image.

### Flask Application Code (`app.py` for each service)

For `hello-service`:
```python
# hello_service/app.py
from flask import Flask, os

app = Flask(__name__)

# Get message from environment variable, which will be sourced from ConfigMap
HELLO_MESSAGE = os.environ.get('HELLO_MESSAGE', 'Default Hello from Hello Service!')

@app.route('/hello')
def hello_world():
    return HELLO_MESSAGE

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

For `greet-service`:
```python
# greet_service/app.py
from flask import Flask, os

app = Flask(__name__)

# Get message from environment variable, which will be sourced from ConfigMap
GREET_MESSAGE = os.environ.get('GREET_MESSAGE', 'Default Greetings from Greet Service!')

@app.route('/greet')
def greet_world():
    return GREET_MESSAGE

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Flask Dockerfile (`Dockerfile` for both services)

You would put the `app.py` and a `requirements.txt` (containing `Flask`) in a directory and build an image.
Example `Dockerfile`:

```dockerfile
# Dockerfile for Flask Backend Services
FROM python:3.9-slim-buster

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

You would build these images locally. We will then load them directly into Kind:

```bash
docker build -t hello-service:1.0 ./hello_service
docker build -t greet-service:1.0 ./greet_service
```

---

### Kubernetes YAMLs for Backend Services

#### 2.1. Namespace for the Application

```yaml
# 00-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-realistic-app # Dedicated namespace for our POC application
  labels:
    app.kubernetes.io/name: realistic-poc # A label for the application
```

#### 2.2. Hello Service (ConfigMap, Deployment, Service)

```yaml
# 01-hello-service-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: hello-service-config # Name of the ConfigMap
  namespace: my-realistic-app # Must be in the same namespace as the service and deployment
data:
  hello_message: "Hello from the Kubernetes Backend!" # The message our Flask app will serve
```
```yaml
# 02-hello-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-service-deployment # Name of the Deployment
  namespace: my-realistic-app
  labels:
    app: hello-service # Label for selector to pick up
spec:
  replicas: 2 # We want two instances of our hello service
  selector:
    matchLabels:
      app: hello-service # Matches the label in the Pod template
  template:
    metadata:
      labels:
        app: hello-service # Label for the Pods created by this Deployment
    spec:
      containers:
      - name: hello-app-container # Name of the container
        image: localhost:5000/hello-service:1.0 # REPLACED: Image path for local registry
        ports:
        - containerPort: 5000 # Flask app listens on port 5000
        env: # Injecting the message from ConfigMap as an environment variable
        - name: HELLO_MESSAGE # Environment variable name in the container
          valueFrom:
            configMapKeyRef:
              name: hello-service-config # Name of the ConfigMap
              key: hello_message # Key from the ConfigMap to use
```
```yaml
# 03-hello-service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-service-clusterip # Name of the Service
  namespace: my-realistic-app
spec:
  selector:
    app: hello-service # Matches the label on the hello-service Pods
  ports:
    - protocol: TCP
      port: 80 # Service port (internal to cluster)
      targetPort: 5000 # Port on the Pod that the service targets (Flask app port)
  type: ClusterIP # Exposes the service internally within the cluster
```

#### 2.3. Greet Service (ConfigMap, Deployment, Service)

```yaml
# 04-greet-service-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: greet-service-config
  namespace: my-realistic-app
data:
  greet_message: "Greetings from the Kubernetes Backend!"
```
```yaml
# 05-greet-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: greet-service-deployment
  namespace: my-realistic-app
  labels:
    app: greet-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: greet-service
  template:
    metadata:
      labels:
        app: greet-service
    spec:
      containers:
      - name: greet-app-container
        image: localhost:5000/greet-service:1.0 # REPLACED: Image path for local registry
        ports:
        - containerPort: 5000
        env:
        - name: GREET_MESSAGE
          valueFrom:
            configMapKeyRef:
              name: greet-service-config
              key: greet_message
```
```yaml
# 06-greet-service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: greet-service-clusterip
  namespace: my-realistic-app
spec:
  selector:
    app: greet-service
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: ClusterIP
```

---

## 3. Frontend Service (Nginx with HTML/JS)

This will be a simple Nginx server serving a static `index.html` file. The JavaScript within `index.html` will make `fetch` requests to the backend services. We'll use a ConfigMap to hold the `index.html` content.

### Frontend HTML/JS (`index.html` content for ConfigMap)

```html
<!-- frontend/index.html content for ConfigMap -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kubernetes POC Frontend</title>
    <style>
        body { font-family: sans-serif; margin: 40px; background-color: #f0f2f5; color: #333; }
        .container { max-width: 800px; margin: 0 auto; background-color: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; margin-bottom: 30px;}
        .section { margin-bottom: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 4px; background-color: #f9f9f9; }
        button {
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
            border: none;
            border-radius: 5px;
            margin-right: 10px;
            background-color: #3498db;
            color: white;
            transition: background-color 0.3s ease;
        }
        button:hover { background-color: #2980b9; }
        .response { margin-top: 10px; padding: 10px; border: 1px solid #eee; background-color: #e9e9e9; border-radius: 4px; }
        .error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Kubernetes POC Frontend</h1>

        <div class="section">
            <h2>Hello Service</h2>
            <button onclick="fetchHello()">Get Hello Message</button>
            <div id="helloResponse" class="response"></div>
        </div>

        <div class="section">
            <h2>Greet Service</h2>
            <button onclick="fetchGreet()">Get Greet Message</button>
            <div id="greetResponse" class="response"></div>
        </div>
    </div>

    <script>
        // These paths are relative because Ingress handles the routing
        const HELLO_API_PATH = '/api/hello';
        const GREET_API_PATH = '/api/greet';

        async function fetchHello() {
            const responseDiv = document.getElementById('helloResponse');
            responseDiv.textContent = 'Loading...';
            try {
                const response = await fetch(HELLO_API_PATH);
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                const data = await response.text(); // Assuming text response from Flask
                responseDiv.textContent = `Response: "${data}"`;
                responseDiv.classList.remove('error');
            } catch (error) {
                responseDiv.textContent = `Error: ${error.message}. Check browser console for details.`;
                responseDiv.classList.add('error');
                console.error('Fetch Hello Error:', error);
            }
        }

        async function fetchGreet() {
            const responseDiv = document.getElementById('greetResponse');
            responseDiv.textContent = 'Loading...';
            try {
                const response = await fetch(GREET_API_PATH);
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                const data = await response.text(); // Assuming text response from Flask
                responseDiv.textContent = `Response: "${data}"`;
                responseDiv.classList.remove('error');
            } catch (error) {
                responseDiv.textContent = `Error: ${error.message}. Check browser console for details.`;
                responseDiv.classList.add('error');
                console.error('Fetch Greet Error:', error);
            }
        }
    </script>
</body>
</html>
```

### Kubernetes YAMLs for Frontend Service

#### 3.1. Frontend ConfigMap (for `index.html`)

```yaml
# 07-frontend-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-html # Name of the ConfigMap
  namespace: my-realistic-app
data:
  index.html: | # The key 'index.html' will be the filename when mounted
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Kubernetes POC Frontend</title>
        <style>
            body { font-family: sans-serif; margin: 40px; background-color: #f0f2f5; color: #333; }
            .container { max-width: 800px; margin: 0 auto; background-color: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
            h1 { color: #2c3e50; text-align: center; margin-bottom: 30px;}
            .section { margin-bottom: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 4px; background-color: #f9f9f9; }
            button {
                padding: 10px 20px;
                font-size: 16px;
                cursor: pointer;
                border: none;
                border-radius: 5px;
                margin-right: 10px;
                background-color: #3498db;
                color: white;
                transition: background-color 0.3s ease;
            }
            button:hover { background-color: #2980b9; }
            .response { margin-top: 10px; padding: 10px; border: 1px solid #eee; background-color: #e9e9e9; border-radius: 4px; }
            .error { color: red; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Kubernetes POC Frontend</h1>

            <div class="section">
                <h2>Hello Service</h2>
                <button onclick="fetchHello()">Get Hello Message</button>
                <div id="helloResponse" class="response"></div>
            </div>

            <div class="section">
                <h2>Greet Service</h2>
                <button onclick="fetchGreet()">Get Greet Message</button>
                <div id="greetResponse" class="response"></div>
            </div>
        </div>

        <script>
            // These paths are relative because Ingress handles the routing
            const HELLO_API_PATH = '/api/hello';
            const GREET_API_PATH = '/api/greet';

            async function fetchHello() {
                const responseDiv = document.getElementById('helloResponse');
                responseDiv.textContent = 'Loading...';
                try {
                    const response = await fetch(HELLO_API_PATH);
                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`);
                    }
                    const data = await response.text(); // Assuming text response from Flask
                    responseDiv.textContent = `Response: "${data}"`;
                    responseDiv.classList.remove('error');
                } catch (error) {
                    responseDiv.textContent = `Error: ${error.message}. Check browser console for details.`;
                    responseDiv.classList.add('error');
                    console.error('Fetch Hello Error:', error);
                }
            }

            async function fetchGreet() {
                const responseDiv = document.getElementById('greetResponse');
                responseDiv.textContent = 'Loading...';
                try {
                    const response = await fetch(GREET_API_PATH);
                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`);
                    }
                    const data = await response.text(); // Assuming text response from Flask
                    responseDiv.textContent = `Response: "${data}"`;
                    responseDiv.classList.remove('error');
                } catch (error) {
                    responseDiv.textContent = `Error: ${error.message}. Check browser console for details.`;
                    responseDiv.classList.add('error');
                    console.error('Fetch Greet Error:', error);
                }
            }
        </script>
    </body>
    </html>
```

#### 3.2. Frontend Deployment (Nginx serving `index.html`)

```yaml
# 08-frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment # Name of the Deployment
  namespace: my-realistic-app
  labels:
    app: frontend # Label for selector to pick up
spec:
  replicas: 1 # A single replica for the frontend
  selector:
    matchLabels:
      app: frontend # Matches the label in the Pod template
  template:
    metadata:
      labels:
        app: frontend # Label for the Pods created by this Deployment
    spec:
      containers:
      - name: frontend-nginx-container # Name of the container
        image: nginx:latest # Standard Nginx image
        ports:
        - containerPort: 80 # Nginx listens on port 80
        volumeMounts:
        - name: html-volume # Mounts the HTML content from ConfigMap
          mountPath: /usr/share/nginx/html/index.html # Specific file path for index.html
          subPath: index.html # Mounts only the 'index.html' key from the ConfigMap
      volumes:
      - name: html-volume # Volume definition for the ConfigMap
        configMap:
          name: frontend-html # Name of the ConfigMap to use
```

#### 3.3. Frontend Service (ClusterIP)

```yaml
# 09-frontend-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-clusterip # Name of the Service
  namespace: my-realistic-app
spec:
  selector:
    app: frontend # Matches the label on the frontend Pods
  ports:
    - protocol: TCP
      port: 80 # Service port
      targetPort: 80 # Nginx container port
  type: ClusterIP # Exposes the service internally
```

---

## 4. Ingress for Routing

This Ingress will serve as the single entry point, routing traffic to the frontend and backend services based on paths.

```yaml
# 10-realistic-app-ingress.yaml
apiVersion: networking.k8s.io/v1 # Ingress API version
kind: Ingress # Type of Kubernetes resource
metadata:
  name: realistic-app-ingress # Name of the Ingress resource
  namespace: my-realistic-app # Ingress should be in the same namespace as services
  annotations:
    # Essential for Nginx Ingress Controller to rewrite paths for backend services
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    # Enables regex matching for the paths defined below
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx # Specifies which Ingress Controller will handle this Ingress
  rules:
  - http:
      paths:
      # Rule for the Frontend UI: serves content at the root path '/'
      - path: / # Matches the root path
        pathType: Prefix # Matches any path starting with /
        backend:
          service:
            name: frontend-clusterip # Directs traffic to the frontend service
            port:
              number: 80 # Port of the frontend service

      # Rule for Hello Service API: routes /api/hello to the hello-service
      # The regex (.*) captures everything after /api/hello and passes it as $2 to rewrite-target
      - path: /api/hello(/|$)(.*) # Matches /api/hello, optionally followed by / and then anything else
        pathType: Prefix
        backend:
          service:
            name: hello-service-clusterip # Directs traffic to the hello service
            port:
              number: 80 # Port of the hello service

      # Rule for Greet Service API: routes /api/greet to the greet-service
      - path: /api/greet(/|$)(.*) # Matches /api/greet, optionally followed by / and then anything else
        pathType: Prefix
        backend:
          service:
            name: greet-service-clusterip # Directs traffic to the greet service
            port:
              number: 80 # Port of the greet service
```

---

## Deployment Steps

To deploy this POC, you would follow these steps:

### 1. Prepare Your Local Docker Environment and Kind Cluster
```bash
sh ./demo-project-1/setup-cluster.sh
```


### 2. Verify Cluster Readiness:

Wait for all your Kind nodes to transition to the `Ready` state.

```bash
kubectl get nodes --show-labels
```

All nodes should eventually show `Ready`.

---

### 2. Install the Nginx Ingress Controller

This step deploys the Nginx Ingress Controller, which will manage Ingress resources in your cluster, into the `ingress-nginx` namespace.

```bash
kubectl apply -f [https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml](https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml)
```

**Verify Ingress Controller Deployment:** Wait for the `ingress-nginx-controller` pod to be `Running` and `Ready`.

```bash
kubectl get pods -n ingress-nginx -w
```

Look for a pod named `ingress-nginx-controller-...` with `1/1` in the `READY` column and `Running` in the `STATUS` column.

---

### 3. Build and Load Docker Images to Your Local Registry

Instead of pushing to a registry, we'll build the Docker images locally and then use kind load docker-image to efficiently transfer them directly into your Kind cluster's nodes.

Build the images:

```bash
docker build -t hello-service:1.0 ./hello_service
docker build -t greet-service:1.0 ./greet_service
```

Load images into Kind:

```bash
kind load docker-image hello-service:1.0 --name k8s-poc-cluster
kind load docker-image greet-service:1.0 --name k8s-poc-cluster
```

This command transfers the specified images from your local Docker daemon's image cache directly to the Kind cluster nodes.

---

### 4. Apply Kubernetes Manifests for Your Applications

Now, apply all the Kubernetes YAML files for your application components in the correct order.

```bash
# Create the dedicated namespace for your application
kubectl apply -f 00-namespace.yaml

# Deploy Hello Service components (ConfigMap, Deployment, Service)
kubectl apply -f 01-hello-service-configmap.yaml
kubectl apply -f 02-hello-service-deployment.yaml
kubectl apply -f 03-hello-service-clusterip.yaml

# Deploy Greet Service components (ConfigMap, Deployment, Service)
kubectl apply -f 04-greet-service-configmap.yaml
kubectl apply -f 05-greet-service-deployment.yaml
kubectl apply -f 06-greet-service-clusterip.yaml

kubectl get configmaps -n my-realistic-app
kubectl get deployments -n my-realistic-app
kubectl get services -n my-realistic-app
kubectl get pods -n my-realistic-app
kubectl logs -n my-realistic-app _pod_name_

# Deploy Frontend Service components (ConfigMap, Deployment, Service)
kubectl apply -f 07-frontend-configmap.yaml
kubectl apply -f 08-frontend-deployment.yaml
kubectl apply -f 09-frontend-clusterip.yaml

# Deploy the Ingress rule to expose your services externally
kubectl apply -f 10-realistic-app-ingress.yaml
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

---

### 5. Verify All Application Components Are Running

After applying the manifests, verify that all your application pods are running and healthy, and that services have correctly discovered their backing pods.

```bash
# Check application pods status
kubectl get pods -n my-realistic-app

# Check application services status and endpoints
kubectl get svc -n my-realistic-app
kubectl get endpoints -n my-realistic-app

# Check Ingress resource status
kubectl get ingress -n my-realistic-app
```

Ensure all pods show `Running` and `1/1` in the `READY` column, and that your services have active `ENDPOINTS` listed (e.g., `10.244.X.Y:Port`).

---

### 6. Test Access via Codespaces Port Forwarding

Finally, you can test your application by port-forwarding the Nginx Ingress Controller's `NodePort` to a local port in your Codespace environment.

* **Run `kubectl port-forward` in a **separate terminal** and leave it running:**
    This will forward traffic from local port `8080` in your Codespace to the Nginx Ingress Controller's `NodePort`.

    ```bash
    kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 --address 0.0.0.0
    ```

* **Access Your Applications in Your Browser:**
    Open the **PORTS** tab in your Codespaces environment (usually at the bottom of VS Code). You should see local port `8080` listed. Codespaces will generate a public URL for it (e.g., `https://your-codespace-name-8080.app.github.dev/`).

    * **Frontend UI:** Navigate to the Codespaces-generated URL for port `8080`, followed by `/`.
        Example: `https://<your-codespace-name>-8080.app.github.dev/`
    * **Hello API (direct test from browser):** Access the API directly.
        Example: `https://<your-codespace-name>-8080.app.github.dev/api/hello`
    * **Greet API (direct test from browser):** Access the API directly.
        Example: `https://<your-codespace-name>-8080.app.github.dev/api/greet`

When you open the frontend UI in your browser, click the "Get Hello Message" and "Get Greet Message" buttons. They should dynamically fetch responses from your backend Flask services, demonstrating the full flow through Ingress.