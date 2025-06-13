# Realistic Kubernetes Chatbot Demo Project (`demo-project-2`)

This project demonstrates a slightly more complex, but still minimalistic, Kubernetes application. It simulates a simple chatbot environment with a frontend, a backend processing service (where AI logic would reside), a PostgreSQL database, a Redis messaging queue, and a basic logging agent, all isolated within its own Kubernetes namespace. It uses `kind load` for efficient image management.

## Project Structure

We'll organize the files in a new directory `demo-project-2` with the following structure:

```
demo-project-2/
├── backend/
│   ├── app.py
│   └── Dockerfile
│   └── requirements.txt
├── frontend/
│   └── index.html
├── kubernetes/
│   ├── 00-namespace.yaml
│   ├── 01-db-secret.yaml
│   ├── 02-db-pv.yaml
│   ├── 03-db-pvc.yaml
│   ├── 04-db-deployment.yaml
│   ├── 05-db-service.yaml
│   ├── 06-redis-deployment.yaml
│   ├── 07-redis-service.yaml
│   ├── 08-backend-configmap.yaml
│   ├── 09-backend-deployment.yaml
│   ├── 10-backend-service.yaml
│   ├── 11-frontend-configmap.yaml
│   ├── 12-frontend-deployment.yaml
│   ├── 13-frontend-service.yaml
│   ├── 14-ingress.yaml
│   └── 15-logging-daemonset.yaml
└── README.md (this file)
```

## Application Code

### 1. Backend Service (`backend/app.py`)

This Flask application simulates the chatbot logic. It includes placeholders for interacting with a database and a messaging queue. For a minimalistic demo, the AI response is a simple string, but the structure for calling an LLM (like Gemini) is provided as a commented example.

```python
# demo-project-2/backend/app.py
from flask import Flask, request, jsonify
import os
import time
import random
# import requests # Uncomment if you want to integrate with an actual LLM API

app = Flask(__name__)

# Environment variables will be populated from Kubernetes Secrets and ConfigMaps
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_NAME = os.environ.get('DB_NAME', 'chatbot_db')
DB_USER = os.environ.get('DB_USER', 'chatbot_user')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'default_password')

REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
REDIS_PORT = os.environ.get('REDIS_PORT', '6379')

# Chatbot AI prompt (from ConfigMap)
AI_PROMPT = os.environ.get('AI_PROMPT', 'You are a friendly chatbot.')

@app.route('/chat', methods=['POST'])
def chat():
    """
    Handles chat messages, simulates AI processing, DB interaction, and messaging.
    """
    user_message = request.json.get('message', '')
    print(f"Received message: {user_message}")

    # Simulate database interaction (e.g., logging message, fetching user history)
    # In a real app, you'd connect to PostgreSQL here using psycopg2
    print(f"Simulating DB interaction for message: {user_message}")
    # time.sleep(0.1) # Simulate network latency

    # Simulate sending message to a queue (e.g., for async processing)
    # In a real app, you'd connect to Redis and publish/subscribe here
    print(f"Simulating Redis interaction for message: {user_message}")
    # time.sleep(0.05) # Simulate network latency

    # --- AI Logic (Minimalistic for demo) ---
    ai_response = "I'm a simple chatbot. I heard: " + user_message

    # Example of calling an LLM (uncomment and configure for actual use)
    # try:
    #     prompt_text = f"{AI_PROMPT}\nUser: {user_message}\nChatbot:"
    #     api_key = os.environ.get("GEMINI_API_KEY", "") # Get API key from environment
    #     if not api_key:
    #         raise ValueError("GEMINI_API_KEY not set for LLM integration.")
    #
    #     payload = {"contents": [{"role": "user", "parts": [{"text": prompt_text}]}]}
    #     api_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
    #     
    #     response = requests.post(api_url, headers={'Content-Type': 'application/json'}, json=payload)
    #     response.raise_for_status() # Raise HTTPError for bad responses (4xx or 5xx)
    #     result = response.json()
    #     
    #     if result.get('candidates') and result['candidates'][0].get('content') and result['candidates'][0]['content'].get('parts'):
    #         ai_response = result['candidates'][0]['content']['parts'][0]['text']
    #     else:
    #         ai_response = "Error: Could not get a valid response from the AI model."
    #         print(f"LLM API response structure unexpected: {result}")
    #
    # except requests.exceptions.RequestException as e:
    #     ai_response = f"Error connecting to AI: {e}"
    #     print(f"LLM API request failed: {e}")
    # except ValueError as e:
    #     ai_response = f"Configuration error: {e}"
    #     print(f"LLM API configuration error: {e}")
    # except Exception as e:
    #     ai_response = f"An unexpected error occurred: {e}"
    #     print(f"Unexpected error in LLM call: {e}")

    return jsonify({"response": ai_response})

@app.route('/healthz')
def healthz():
    """Simple health check endpoint for liveness and readiness probes."""
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### 2. Backend Dockerfile (`backend/Dockerfile`)

```dockerfile
# demo-project-2/backend/Dockerfile
FROM python:3.9-slim-buster

WORKDIR /app

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the Flask application
COPY backend/app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

### 3. Backend Requirements (`backend/requirements.txt`)

```
# demo-project-2/backend/requirements.txt
Flask
requests # For potential LLM API calls
```

### 4. Frontend HTML/JS (`frontend/index.html`)

A simple web page with a chat input and display area. It makes `fetch` requests to the backend.

```html
<!-- demo-project-2/frontend/index.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kubernetes Chatbot Demo</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f7f6; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .chat-container {
            background-color: #ffffff;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            width: 90%;
            max-width: 600px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            min-height: 400px;
            max-height: 80vh;
        }
        .chat-header {
            background-color: #4CAF50;
            color: white;
            padding: 15px;
            font-size: 1.2em;
            text-align: center;
            border-bottom: 1px solid #ddd;
        }
        .chat-messages {
            flex-grow: 1;
            padding: 20px;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
        }
        .message {
            margin-bottom: 15px;
            padding: 10px 15px;
            border-radius: 8px;
            max-width: 80%;
            word-wrap: break-word;
            line-height: 1.5;
        }
        .user-message {
            align-self: flex-end;
            background-color: #DCF8C6;
            color: #333;
            margin-left: auto;
        }
        .bot-message {
            align-self: flex-start;
            background-color: #E8E8E8;
            color: #333;
            margin-right: auto;
        }
        .chat-input-area {
            display: flex;
            padding: 15px;
            border-top: 1px solid #eee;
        }
        .chat-input-area input[type="text"] {
            flex-grow: 1;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            margin-right: 10px;
            font-size: 1em;
        }
        .chat-input-area button {
            background-color: #007BFF;
            color: white;
            border: none;
            border-radius: 5px;
            padding: 10px 15px;
            cursor: pointer;
            font-size: 1em;
            transition: background-color 0.2s;
        }
        .chat-input-area button:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>
    <div class="chat-container">
        <div class="chat-header">Kubernetes Chatbot</div>
        <div class="chat-messages" id="chatMessages">
            <div class="message bot-message">Hello! Type a message to chat.</div>
        </div>
        <div class="chat-input-area">
            <input type="text" id="messageInput" placeholder="Type your message..." onkeypress="handleKeyPress(event)">
            <button onclick="sendMessage()">Send</button>
        </div>
    </div>

    <script>
        const chatMessages = document.getElementById('chatMessages');
        const messageInput = document.getElementById('messageInput');
        const CHAT_API_PATH = '/api/chat'; // Ingress will route this to backend

        function addMessage(text, sender) {
            const messageDiv = document.createElement('div');
            messageDiv.classList.add('message');
            messageDiv.classList.add(sender === 'user' ? 'user-message' : 'bot-message');
            messageDiv.textContent = text;
            chatMessages.appendChild(messageDiv);
            chatMessages.scrollTop = chatMessages.scrollHeight; // Scroll to bottom
        }

        async function sendMessage() {
            const message = messageInput.value.trim();
            if (message === '') return;

            addMessage(message, 'user');
            messageInput.value = '';

            addMessage('Thinking...', 'bot'); // Show thinking message

            try {
                const response = await fetch(CHAT_API_PATH, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ message: message })
                });

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const data = await response.json();
                // Remove "Thinking..." message before adding actual response
                chatMessages.removeChild(chatMessages.lastChild); 
                addMessage(data.response, 'bot');

            } catch (error) {
                console.error('Error sending message:', error);
                chatMessages.removeChild(chatMessages.lastChild); // Remove thinking message
                addMessage(`Error: Could not connect to chatbot. (${error.message})`, 'bot');
            }
        }

        function handleKeyPress(event) {
            if (event.key === 'Enter') {
                sendMessage();
            }
        }
    </script>
</body>
</html>
```

---

## Kubernetes Manifests (YAML Files)

Place these files in the `kubernetes/` directory. They are ordered for logical application.

### 0. Namespace (`kubernetes/00-namespace.yaml`)

```yaml
# demo-project-2/kubernetes/00-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo-project-2-ns # Dedicated namespace for this project
  labels:
    project: chatbot-demo
```

### 1. Database Secret (`kubernetes/01-db-secret.yaml`)

Holds sensitive database credentials.

```yaml
# demo-project-2/kubernetes/01-db-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials # Name of the secret
  namespace: demo-project-2-ns # Must be in the same namespace
type: Opaque # A general purpose secret type
data:
  # Base64 encoded values for username and password
  # 'admin' -> YWRtaW4=
  # 'dbpassword' -> ZGJwYXNzd29yZA==
  username: YWRtaW4= # echo -n "admin" | base64
  password: ZGJwYXNzd29yZA== # echo -n "dbpassword" | base64
```

### 2. Database Persistent Volume (`kubernetes/02-db-pv.yaml`)

Defines a piece of storage for the PostgreSQL database. Using `hostPath` for simplicity in Kind.

```yaml
# demo-project-2/kubernetes/02-db-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv-volume # Name of the Persistent Volume
spec:
  capacity:
    storage: 2Gi # Capacity of the volume
  accessModes:
    - ReadWriteOnce # Can be mounted as read-write by a single node
  persistentVolumeReclaimPolicy: Retain # Retain data even if PVC is deleted
  storageClassName: manual # Custom storage class name
  hostPath: # For Kind, we use hostPath to simulate persistent storage on the node
    path: "/mnt/data/postgres" # Directory on the Kind node
    type: DirectoryOrCreate # Create if it doesn't exist
```

### 3. Database Persistent Volume Claim (`kubernetes/03-db-pvc.yaml`)

Requests storage for the PostgreSQL database from an available PV.

```yaml
# demo-project-2/kubernetes/03-db-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pv-claim # Name of the Persistent Volume Claim
  namespace: demo-project-2-ns # Must be in the same namespace
spec:
  accessModes:
    - ReadWriteOnce # Must match accessModes of the PV
  resources:
    requests:
      storage: 1Gi # Requesting 1Gi of storage
  storageClassName: manual # Must match storageClassName of the PV
```

### 4. Database Deployment (`kubernetes/04-db-deployment.yaml`)

Deploys a PostgreSQL database.

```yaml
# demo-project-2/kubernetes/04-db-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db-deployment
  namespace: demo-project-2-ns
  labels:
    app: postgres-db
spec:
  replicas: 1 # A single replica for the database
  selector:
    matchLabels:
      app: postgres-db
  template:
    metadata:
      labels:
        app: postgres-db
    spec:
      containers:
      - name: postgres-db-container
        image: postgres:13 # PostgreSQL image
        ports:
        - containerPort: 5432 # Default PostgreSQL port
        env:
        - name: POSTGRES_DB # Database name
          value: chatbot_db
        - name: POSTGRES_USER # Database user (from secret)
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: username
        - name: POSTGRES_PASSWORD # Database password (from secret)
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        volumeMounts:
        - name: postgres-storage # Mount the PVC
          mountPath: /var/lib/postgresql/data # Default data directory for Postgres
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pv-claim # Reference the PVC
```

### 5. Database Service (`kubernetes/05-db-service.yaml`)

Exposes the PostgreSQL database internally within the cluster.

```yaml
# demo-project-2/kubernetes/05-db-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-db-clusterip # Internal DNS name for the database
  namespace: demo-project-2-ns
spec:
  selector:
    app: postgres-db # Matches the database deployment pods
  ports:
    - protocol: TCP
      port: 5432 # Service port
      targetPort: 5432 # Target container port
  type: ClusterIP
```

### 6. Redis Deployment (`kubernetes/06-redis-deployment.yaml`)

Deploys a Redis instance for messaging.

```yaml
# demo-project-2/kubernetes/06-redis-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-deployment
  namespace: demo-project-2-ns
  labels:
    app: redis-mq
spec:
  replicas: 1 # A single replica for Redis
  selector:
    matchLabels:
      app: redis-mq
  template:
    metadata:
      labels:
        app: redis-mq
    spec:
      containers:
      - name: redis-container
        image: redis:6 # Redis image
        ports:
        - containerPort: 6379 # Default Redis port
```

### 7. Redis Service (`kubernetes/07-redis-service.yaml`)

Exposes the Redis instance internally within the cluster.

```yaml
# demo-project-2/kubernetes/07-redis-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-mq-clusterip # Internal DNS name for Redis
  namespace: demo-project-2-ns
spec:
  selector:
    app: redis-mq # Matches the Redis deployment pods
  ports:
    - protocol: TCP
      port: 6379 # Service port
      targetPort: 6379 # Target container port
  type: ClusterIP
```

### 8. Backend ConfigMap (`kubernetes/08-backend-configmap.yaml`)

Provides non-sensitive configuration for the backend chatbot, like the AI prompt.

```yaml
# demo-project-2/kubernetes/08-backend-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: chatbot-backend-config # Name of the ConfigMap
  namespace: demo-project-2-ns
data:
  ai_prompt: "You are a witty and helpful chatbot designed for Kubernetes enthusiasts. Respond concisely."
  # You could add other configuration here, e.g., API_URL for an external LLM
```

### 9. Backend Deployment (`kubernetes/09-backend-deployment.yaml`)

Deploys the chatbot backend application.

```yaml
# demo-project-2/kubernetes/09-backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chatbot-backend-deployment
  namespace: demo-project-2-ns
  labels:
    app: chatbot-backend
spec:
  replicas: 2 # Scale out the backend for resilience
  selector:
    matchLabels:
      app: chatbot-backend
  template:
    metadata:
      labels:
        app: chatbot-backend
    spec:
      containers:
      - name: chatbot-backend-container
        image: chatbot-backend:1.0 # Image built from backend/Dockerfile
        ports:
        - containerPort: 5000 # Flask app port
        env:
        # Pass DB connection details from Secret and Service
        - name: DB_HOST
          value: postgres-db-clusterip # Service name provides stable internal DNS
        - name: DB_NAME
          value: chatbot_db
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        # Pass Redis connection details from Service
        - name: REDIS_HOST
          value: redis-mq-clusterip # Service name provides stable internal DNS
        - name: REDIS_PORT
          value: "6379" # Redis port
        # Pass AI prompt from ConfigMap
        - name: AI_PROMPT
          valueFrom:
            configMapKeyRef:
              name: chatbot-backend-config
              key: ai_prompt
        # Liveness and Readiness probes for health checking
        livenessProbe:
          httpGet:
            path: /healthz # Health endpoint in app.py
            port: 5000
          initialDelaySeconds: 10 # Wait 10s before first check
          periodSeconds: 5 # Check every 5s
          timeoutSeconds: 2 # Timeout after 2s
          failureThreshold: 3 # Restart after 3 failures
        readinessProbe:
          httpGet:
            path: /healthz
            port: 5000
          initialDelaySeconds: 5 # Wait 5s before first check
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 1 # Stop sending traffic after 1 failure
```

### 10. Backend Service (`kubernetes/10-backend-service.yaml`)

Exposes the chatbot backend internally for access by the frontend and Ingress.

```yaml
# demo-project-2/kubernetes/10-backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: chatbot-backend-clusterip # Internal DNS name for the backend
  namespace: demo-project-2-ns
spec:
  selector:
    app: chatbot-backend # Matches the backend deployment pods
  ports:
    - protocol: TCP
      port: 80 # Service port (frontend will call /api/chat which ingress maps to /chat on backend)
      targetPort: 5000 # Target container port (Flask app's port)
  type: ClusterIP
```

### 11. Frontend ConfigMap (`kubernetes/11-frontend-configmap.yaml`)

Holds the static HTML content for the frontend.

```yaml
# demo-project-2/kubernetes/11-frontend-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: chatbot-frontend-html # Name of the ConfigMap
  namespace: demo-project-2-ns
data:
  index.html: | # The key 'index.html' will be the filename when mounted
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Kubernetes Chatbot Demo</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f7f6; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
            .chat-container {
                background-color: #ffffff;
                border-radius: 10px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
                width: 90%;
                max-width: 600px;
                overflow: hidden;
                display: flex;
                flex-direction: column;
                min-height: 400px;
                max-height: 80vh;
            }
            .chat-header {
                background-color: #4CAF50;
                color: white;
                padding: 15px;
                font-size: 1.2em;
                text-align: center;
                border-bottom: 1px solid #ddd;
            }
            .chat-messages {
                flex-grow: 1;
                padding: 20px;
                overflow-y: auto;
                display: flex;
                flex-direction: column;
            }
            .message {
                margin-bottom: 15px;
                padding: 10px 15px;
                border-radius: 8px;
                max-width: 80%;
                word-wrap: break-word;
                line-height: 1.5;
            }
            .user-message {
                align-self: flex-end;
                background-color: #DCF8C6;
                color: #333;
                margin-left: auto;
            }
            .bot-message {
                align-self: flex-start;
                background-color: #E8E8E8;
                color: #333;
                margin-right: auto;
            }
            .chat-input-area {
                display: flex;
                padding: 15px;
                border-top: 1px solid #eee;
            }
            .chat-input-area input[type="text"] {
                flex-grow: 1;
                padding: 10px;
                border: 1px solid #ddd;
                border-radius: 5px;
                margin-right: 10px;
                font-size: 1em;
            }
            .chat-input-area button {
                background-color: #007BFF;
                color: white;
                border: none;
                border-radius: 5px;
                padding: 10px 15px;
                cursor: pointer;
                font-size: 1em;
                transition: background-color 0.2s;
            }
            .chat-input-area button:hover {
                background-color: #0056b3;
            }
        </style>
    </head>
    <body>
        <div class="chat-container">
            <div class="chat-header">Kubernetes Chatbot</div>
            <div class="chat-messages" id="chatMessages">
                <div class="message bot-message">Hello! Type a message to chat.</div>
            </div>
            <div class="chat-input-area">
                <input type="text" id="messageInput" placeholder="Type your message..." onkeypress="handleKeyPress(event)">
                <button onclick="sendMessage()">Send</button>
            </div>
        </div>

        <script>
            const chatMessages = document.getElementById('chatMessages');
            const messageInput = document.getElementById('messageInput');
            const CHAT_API_PATH = '/api/chat'; // Ingress will route this to backend

            function addMessage(text, sender) {
                const messageDiv = document.createElement('div');
                messageDiv.classList.add('message');
                messageDiv.classList.add(sender === 'user' ? 'user-message' : 'bot-message');
                messageDiv.textContent = text;
                chatMessages.appendChild(messageDiv);
                chatMessages.scrollTop = chatMessages.scrollHeight; // Scroll to bottom
            }

            async function sendMessage() {
                const message = messageInput.value.trim();
                if (message === '') return;

                addMessage(message, 'user');
                messageInput.value = '';

                addMessage('Thinking...', 'bot'); // Show thinking message

                try {
                    const response = await fetch(CHAT_API_PATH, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({ message: message })
                    });

                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`);
                    }

                    const data = await response.json();
                    // Remove "Thinking..." message before adding actual response
                    chatMessages.removeChild(chatMessages.lastChild); 
                    addMessage(data.response, 'bot');

                } catch (error) {
                    console.error('Error sending message:', error);
                    chatMessages.removeChild(chatMessages.lastChild); // Remove thinking message
                    addMessage(`Error: Could not connect to chatbot. (${error.message})`, 'bot');
                }
            }

            function handleKeyPress(event) {
                if (event.key === 'Enter') {
                    sendMessage();
                }
            }
        </script>
    </body>
    </html>
```

### 12. Frontend Deployment (`kubernetes/12-frontend-deployment.yaml`)

Deploys the Nginx server to serve the static frontend HTML.

```yaml
# demo-project-2/kubernetes/12-frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chatbot-frontend-deployment
  namespace: demo-project-2-ns
  labels:
    app: chatbot-frontend
spec:
  replicas: 1 # Single replica for the frontend
  selector:
    matchLabels:
      app: chatbot-frontend
  template:
    metadata:
      labels:
        app: chatbot-frontend
    spec:
      containers:
      - name: frontend-nginx-container
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
          name: chatbot-frontend-html # Name of the ConfigMap to use
```

### 13. Frontend Service (`kubernetes/13-frontend-service.yaml`)

Exposes the frontend internally for access via Ingress.

```yaml
# demo-project-2/kubernetes/13-frontend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: chatbot-frontend-clusterip # Internal DNS name for the frontend
  namespace: demo-project-2-ns
spec:
  selector:
    app: chatbot-frontend # Matches the frontend deployment pods
  ports:
    - protocol: TCP
      port: 80 # Service port
      targetPort: 80 # Nginx container port
  type: ClusterIP
```

### 14. Ingress (`kubernetes/14-ingress.yaml`)

Routes external traffic to the frontend and backend services.

```yaml
# demo-project-2/kubernetes/14-ingress.yaml
apiVersion: networking.k8s.io/v1 # Ingress API version
kind: Ingress # Type of Kubernetes resource
metadata:
  name: chatbot-app-ingress # Name of the Ingress resource
  namespace: demo-project-2-ns
  annotations:
    # This annotation is crucial for path rewriting with Nginx Ingress Controller.
    # It tells the controller to rewrite the URI that is sent to the backend.
    # The value /$1 means that the matched group from the regex (everything after the /api/)
    # will be used as the new target path.
    nginx.ingress.kubernetes.io/rewrite-target: /$1

    # This annotation enables regex support for the paths defined below.
    # It's needed when using capture groups for rewrite-target.
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx # Specifies which Ingress Controller will handle this Ingress
  rules:
  - http:
      paths:
      # Rule for the Frontend UI: serves content at the root path '/'
      - path: / # Matches the root path
        pathType: Prefix
        backend:
          service:
            name: chatbot-frontend-clusterip # Directs traffic to the frontend service
            port:
              number: 80

      # Rule for Chatbot Backend API: routes /api/chat to the backend service.
      # The regex (chat.*) captures 'chat' and any subpath, making it $1.
      # This ensures the backend Flask app receives '/chat' (or /chat/subpath) as its route.
      - path: /api/(chat.*) # Matches /api/chat and any subpath
        pathType: Prefix
        backend:
          service:
            name: chatbot-backend-clusterip # Directs traffic to the backend service
            port:
              number: 80
```

### 15. Logging DaemonSet (`kubernetes/15-logging-daemonset.yaml`)

A minimalistic example of a DaemonSet. This will deploy a small `busybox` container on each node that simply logs its hostname, demonstrating how you might run a logging agent on every node.

```yaml
# demo-project-2/kubernetes/15-logging-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-logger-daemonset
  namespace: demo-project-2-ns # Logs for this demo project
  labels:
    app: node-logger
spec:
  selector:
    matchLabels:
      app: node-logger
  template:
    metadata:
      labels:
        app: node-logger
    spec:
      # This toleration allows the DaemonSet to run on the control-plane node too in Kind.
      # In a real cluster, you might only target worker nodes or have specific node selectors.
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: logger-container
        image: busybox:latest # A very light image
        command: ["/bin/sh", "-c", "while true; do echo 'Node-Logger: Hostname is $(HOSTNAME) - Pod IP is $(POD_IP)'; sleep 10; done"]
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP # Injects the Pod's IP into an env var
```

---

## Deployment Steps

Follow these steps carefully to deploy the entire demo project.

### 1. Create Project Directory and Place Files

Create the `demo-project-2` directory and its subdirectories (`backend`, `frontend`, `kubernetes`). Then, copy the respective code and YAML files into their correct locations as outlined in the "Project Structure" section above.

### 2. Build Docker Images

Navigate to the `demo-project-2` directory in your terminal.

```bash
cd demo-project-2

# Build the backend service image
docker build -t chatbot-backend:1.0 -f backend/Dockerfile .

# No Dockerfile for frontend as it uses standard Nginx image.
# You could optionally build a custom Nginx image if needed, but for this demo, it's not.
```

### 3. Prepare Your Kind Cluster

Ensure you have a Kind cluster running. If you have an existing one, it's usually best to start fresh for new complex setups.

```bash
# Delete any existing Kind cluster to ensure a clean setup
kind delete cluster --name k8s-poc-cluster || true

# Create Kind cluster
# The extraPortMappings are essential for Ingress to be accessible from your host (Codespace)
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: k8s-poc-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true" # Label for Nginx Ingress Controller
  extraPortMappings:
  - containerPort: 80 # Map host port 80 to control-plane node's port 80 for Ingress HTTP
    hostPort: 80
    protocol: TCP
  - containerPort: 443 # Map host port 443 to control-plane node's port 443 for Ingress HTTPS
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF
```

**Verify Cluster Setup:**

```bash
kubectl get nodes
```
Ensure all nodes are `Ready`.

### 4. Load Docker Images into Kind

Transfer the Docker images you just built directly into your Kind cluster. This bypasses the need for a local Docker registry.

```bash
# Load the backend chatbot image
kind load docker-image chatbot-backend:1.0 --name k8s-poc-cluster

# No need to load nginx:latest as it's a public image Kubernetes can pull.
# If you used a custom frontend image, you would load it here:
# kind load docker-image custom-frontend:1.0 --name k8s-poc-cluster
```

### 5. Label Your Nodes for the Ingress Controller

The `kind create cluster` command already added the `ingress-ready=true` label to the control-plane node as per the configuration. You can verify:

```bash
kubectl get nodes --show-labels
```
Look for `ingress-ready=true` on `k8s-poc-cluster-control-plane`.

### 6. Install the Nginx Ingress Controller

This deploys the Nginx Ingress Controller.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
```

**Verify Ingress Controller Deployment:**

```bash
kubectl get pods -n ingress-nginx -w
```
Wait for the `ingress-nginx-controller-...` pod to be `Running` and `Ready`.

### 7. Apply Kubernetes Manifests for Your Applications

Now, apply all the Kubernetes YAML files for your demo application. It's crucial to apply them in a logical order (namespace first, then secrets/PV/PVCs, then services, deployments, and finally ingress).

```bash
cd kubernetes/ # Make sure you are in the kubernetes directory

# Create the namespace
kubectl apply -f 00-namespace.yaml

# Create the database secret, PV, PVC, Deployment, and Service
kubectl apply -f 01-db-secret.yaml
kubectl get secrets -n demo-project-2-ns
kubectl apply -f 02-db-pv.yaml
kubectl get pv
kubectl apply -f 03-db-pvc.yaml
kubectl get pvc -n demo-project-2-ns
kubectl apply -f 04-db-deployment.yaml
kubectl get pods -n demo-project-2-ns
kubectl apply -f 05-db-service.yaml

# Create the Redis Deployment and Service
kubectl apply -f 06-redis-deployment.yaml
kubectl apply -f 07-redis-service.yaml

# Create the Backend ConfigMap, Deployment, and Service
kubectl apply -f 08-backend-configmap.yaml
kubectl apply -f 09-backend-deployment.yaml
kubectl apply -f 10-backend-service.yaml

kubectl get pods -n demo-project-2-ns
kubectl get services -n demo-project-2-ns

# Create the Frontend ConfigMap, Deployment, and Service
kubectl apply -f 11-frontend-configmap.yaml
kubectl apply -f 12-frontend-deployment.yaml
kubectl apply -f 13-frontend-service.yaml

# Create the Ingress rule
kubectl apply -f 14-ingress.yaml
kubectl get ingress -n demo-project-2-ns
kubectl get endpoints -n demo-project-2-ns
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Deploy the logging DaemonSet
kubectl apply -f 15-logging-daemonset.yaml
```

### 8. Verify All Application Components Are Running

Check the status of all your resources in the `demo-project-2-ns` namespace.

```bash
kubectl get all -n demo-project-2-ns
```
Ensure all Pods are `Running` and `READY` (e.g., `1/1` for single-container pods). Check for `Bound` status on PVCs and `Running` status on Deployments.

You can also check the logs of your services:
```bash
kubectl logs -f -l app=chatbot-backend -n demo-project-2-ns
kubectl logs -f -l app=node-logger -n demo-project-2-ns
```

### 9. Test Access via Codespaces Port Forwarding

Finally, access your chatbot application through the Ingress.

* **Run `kubectl port-forward` in a **separate terminal** and leave it running:**
    This will forward traffic from local port `8080` in your Codespace to the Nginx Ingress Controller's `NodePort`.

    ```bash
    kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 --address 0.0.0.0
    ```

* **Access Your Chatbot in Your Browser:**
    Open the **PORTS** tab in your Codespaces environment. You should see local port `8080` listed. Codespaces will generate a public URL for it (e.g., `https://your-codespace-name-8080.app.github.dev/`).

    * Navigate to this URL. You should see the chatbot frontend. Type a message and hit "Send" to interact with your backend service.

---

Remember to clean up your cluster resources when you're done experimenting to save resources:

```bash
# Delete all resources in your namespace
kubectl delete namespace demo-project-2-ns

# Delete the Persistent Volume (PVC deletion won't remove PV if policy is Retain)
kubectl delete pv postgres-pv-volume

# Delete the Kind cluster
kind delete cluster --name k8s-poc-cluster

# Optionally clean up Docker images if you don't need them
docker rmi chatbot-backend:1.0