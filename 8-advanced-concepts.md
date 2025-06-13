# Kubernetes Advanced Concepts Playground

This document introduces several key Kubernetes concepts beyond the basics of Pods, Deployments, Services, and Ingress. Each section explains a concept, why it's important, and provides instructions on how to set up simple experiments to understand its functionality.

---

## 1. Volumes and Persistent Volumes (PV/PVC)

**Volumes** provide a way to store and access data that is independent of the Pod's lifecycle. Without a Volume, data inside a container is ephemeral – it's lost when the container restarts or the Pod is deleted.

**Persistent Volumes (PV)** are pieces of storage in the cluster that have been provisioned by an administrator or dynamically provisioned using Storage Classes. They are a resource in the cluster.

**Persistent Volume Claims (PVC)** are requests for storage by a user. A PVC consumes PV resources.

### Why are they important?

* **Data Persistence:** Essential for stateful applications (databases, message queues) where data must survive Pod restarts or failures.
* **Decoupling Storage:** Separates storage management from application deployment.
* **Shared Storage:** Can allow multiple Pods to share the same storage volume.

### How to Play Around:

This requires a storage provisioner. For Kind, you can use the default `hostPath` for local testing (not for production!) or deploy something like MetalLB for a more realistic setup.

1.  **Example: `hostPath` Volume (for quick local testing)**
    This will store data directly on the Kind node's filesystem. If the Kind cluster is deleted, the data is lost.
    ```yaml
    # my-hostpath-app-deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-app-with-volume
      namespace: my-realistic-app
    spec:
      template:
        spec:
          containers:
          - name: nginx-container
            image: nginx:latest
            volumeMounts:
            - name: my-data-volume
              mountPath: /usr/share/nginx/html/data # Mount point inside the container
          volumes:
          - name: my-data-volume
            hostPath:
              path: /tmp/nginx-data # Path on the Kind node where data will be stored
              type: DirectoryOrCreate
    ```
    * Apply this Deployment: `kubectl apply -f my-hostpath-app-deployment.yaml -n my-realistic-app`
    * Access the pod's shell and create a file in `/usr/share/nginx/html/data`.
    * Delete the pod (`kubectl delete pod <pod-name> -n my-realistic-app`).
    * Observe if the new pod (created by the deployment) still has the file. (It should, as it's bound to the same `hostPath` on the node).
    * **Caution:** If you delete the Kind cluster, the `/tmp/nginx-data` on the underlying Docker containers (Kind nodes) will be lost.

2.  **Example: Persistent Volume (PV) and Persistent Volume Claim (PVC)**
    This is the standard, more robust way for persistent storage.

    ```yaml
    # my-pv.yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: my-pv-volume
    spec:
      capacity:
        storage: 1Gi # Size of the volume
      accessModes:
        - ReadWriteOnce # Can be mounted as read-write by a single node
      hostPath: # For Kind, we still use hostPath here
        path: "/mnt/data" # Path on the node where data will live
    ---
    # my-pvc.yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: my-pvc-claim
      namespace: my-realistic-app
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 500Mi # Requesting 500Mi of storage
    ```
    * Apply PV: `kubectl apply -f my-pv.yaml`
    * Apply PVC: `kubectl apply -f my-pvc.yaml -n my-realistic-app`
    * Verify PV/PVC status: `kubectl get pv`, `kubectl get pvc -n my-realistic-app`. The PVC should eventually be `Bound` to the PV.

    ```yaml
    # my-app-with-pvc-deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-app-with-pvc
      namespace: my-realistic-app
    spec:
      template:
        spec:
          containers:
          - name: nginx-container
            image: nginx:latest
            volumeMounts:
            - name: persistent-storage
              mountPath: /usr/share/nginx/html/data # Mount path in container
          volumes:
          - name: persistent-storage
            persistentVolumeClaim:
              claimName: my-pvc-claim # Reference the PVC
    ```
    * Apply this Deployment: `kubectl apply -f my-app-with-pvc-deployment.yaml -n my-realistic-app`
    * Again, create a file inside the pod, delete the pod, and observe persistence. Data should survive as long as the PV exists.

---

## 2. Liveness and Readiness Probes

**Liveness probes** tell Kubernetes when to restart a container. If a liveness probe fails, Kubernetes kills the container, and the container's restart policy dictates what happens next.

**Readiness probes** tell Kubernetes when a container is ready to start accepting traffic. If a readiness probe fails, Kubernetes removes the Pod's IP address from the endpoints of all Services, preventing traffic from reaching it.

### Why are they important?

* **Reliability:** Ensures your applications are truly healthy and able to serve requests.
* **Availability:** Prevents traffic from being sent to unhealthy instances.
* **Self-healing:** Automates recovery from application deadlocks or unresponsiveness.

### How to Play Around:

You can test these with a simple web server that has a `/healthz` endpoint.

1.  **Modify a Deployment YAML (e.g., your `hello-service` deployment):**
    ```yaml
    # 02-hello-service-deployment.yaml (modified snippet)
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hello-service-deployment
      namespace: my-realistic-app
    spec:
      template:
        spec:
          containers:
          - name: hello-app-container
            image: hello-service:1.0 # Your Flask app
            ports:
            - containerPort: 5000
            livenessProbe:
              httpGet:
                path: /hello # Your Flask app's endpoint
                port: 5000
              initialDelaySeconds: 5 # Wait 5 seconds before first check
              periodSeconds: 5     # Check every 5 seconds
              timeoutSeconds: 2    # Timeout after 2 seconds
              failureThreshold: 3  # After 3 failures, restart
            readinessProbe:
              httpGet:
                path: /hello
                port: 5000
              initialDelaySeconds: 5
              periodSeconds: 5
              timeoutSeconds: 2
              failureThreshold: 1 # After 1 failure, stop sending traffic
    ```
    * Apply the updated deployment: `kubectl apply -f 02-hello-service-deployment.yaml -n my-realistic-app`
    * **To simulate a failure:** You can try to temporarily break your Flask app (e.g., introduce a bug that makes `/hello` return a 500 error or just stop responding).
    * Observe pod status: `kubectl get pods -n my-realistic-app -w`
        * You'll see restarts if liveness fails.
        * You'll see Pods becoming `Unready` if readiness fails, and traffic won't go to them.
    * **To trigger readiness failure only (for testing):** You could temporarily modify your Flask app to have a `/ready` endpoint that initially returns 200, then returns 500 after a few requests.

---

## 3. Horizontal Pod Autoscaler (HPA)

The **Horizontal Pod Autoscaler (HPA)** automatically scales the number of Pods in a Deployment (or other scalable resource like ReplicaSet, StatefulSet) based on observed CPU utilization or custom metrics.

### Why are they important?

* **Elasticity:** Automatically adjusts application capacity to match demand, improving performance and cost efficiency.
* **Cost Optimization:** Scales down during low demand, reducing resource consumption.
* **High Availability:** Scales up during peak loads, preventing slowdowns or outages.

### How to Play Around:

This requires the Kubernetes metrics server to be installed in your cluster (it's often pre-installed in Kind).

1.  **Ensure Metrics Server is Running:**
    ```bash
    kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
    # Check if pods in kube-system namespace named 'metrics-server' are running.
    kubectl get pods -n kube-system | grep metrics-server
    ```
    If not, you might need to install it (Kind usually has it, but if not, search for "install metrics server kubernetes").

2.  **Create an HPA for your `hello-service` Deployment:**
    ```bash
    kubectl autoscale deployment hello-service-deployment --cpu-percent=50 --min=1 --max=5 -n my-realistic-app
    ```
    * `--cpu-percent=50`: Target 50% CPU utilization.
    * `--min=1`: Minimum number of replicas.
    * `--max=5`: Maximum number of replicas.

3.  **Verify HPA:**
    ```bash
    kubectl get hpa -n my-realistic-app
    ```
    You'll see the current utilization, target, min/max replicas, and current replicas.

4.  **Generate Load (to trigger scaling):**
    * Open a new terminal.
    * Find the internal IP of your `hello-service-clusterip` (from `kubectl get svc -n my-realistic-app`).
    * Use a tool like `hey` (ApacheBench `ab`, or `curl` in a loop) to generate traffic.
        * **Install `hey` if you don't have it:** `go install github.com/rakyll/hey@latest` (requires Go installed)
        * **Generate load:**
            ```bash
            # Replace <HELLO_SERVICE_CLUSTER_IP> with the actual IP from kubectl get svc
            # And /hello with the actual route in your Flask app
            hey -n 10000 -c 50 http://<HELLO_SERVICE_CLUSTER_IP>:80/hello
            ```
            (Note: if your Flask app is on `/`, then use `/` instead of `/hello`).
    * Monitor the HPA: `kubectl get hpa -n my-realistic-app -w`
        * You should observe the `CURRENT` replicas increasing as CPU utilization goes up. When the load stops, it will scale down.

---

## 4. Jobs and CronJobs

**Jobs** are used for running a specific task to completion. Once the task is successfully completed, the Job terminates. If the Pod fails, the Job will reschedule it until it succeeds.

**CronJobs** are designed for running Jobs on a recurring schedule, similar to `cron` in Linux.

### Why are they important?

* **Batch Processing:** Ideal for one-off tasks, data processing, reporting, or scheduled operations.
* **Reliability:** Jobs retry failed Pods to ensure task completion.
* **Automation:** Automate repetitive tasks without manual intervention.

### How to Play Around:

1.  **Example: A simple Job (runs once, then completes)**
    ```yaml
    # my-job.yaml
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: pi-calculator-job
      namespace: my-realistic-app
    spec:
      template:
        spec:
          containers:
          - name: pi-calculator
            image: perl # A simple image with Perl installed
            command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"] # Calculate Pi
          restartPolicy: OnFailure # Pod will be restarted if it fails
      backoffLimit: 4 # Max retries
    ```
    * Apply the Job: `kubectl apply -f my-job.yaml -n my-realistic-app`
    * Monitor its status: `kubectl get jobs -n my-realistic-app`
    * Check Pods created by the Job: `kubectl get pods -l job-name=pi-calculator-job -n my-realistic-app`
    * View logs: `kubectl logs <pod-name-from-job> -n my-realistic-app` (Once it completes, the pod will still exist in a `Completed` state for log viewing).

2.  **Example: A simple CronJob (runs on a schedule)**
    ```yaml
    # my-cronjob.yaml
    apiVersion: batch/v1
    kind: CronJob
    metadata:
      name: hello-world-cronjob
      namespace: my-realistic-app
    spec:
      schedule: "*/1 * * * *" # Runs every minute
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: hello-logger
                image: busybox:latest
                command: ["sh", "-c", "echo 'Hello from CronJob: $(date)'"]
              restartPolicy: OnFailure
    ```
    * Apply the CronJob: `kubectl apply -f my-cronjob.yaml -n my-realistic-app`
    * Monitor CronJob status: `kubectl get cronjob -n my-realistic-app`
    * Observe Jobs being created: `kubectl get jobs -n my-realistic-app -w` (you'll see new jobs every minute)
    * Check logs of the latest job run (get the most recent job name, then its pod name):
        ```bash
        LATEST_JOB_NAME=$(kubectl get jobs -n my-realistic-app -o=jsonpath='{.items[-1].metadata.name}')
        LATEST_POD_NAME=$(kubectl get pods -n my-realistic-app -l job-name=${LATEST_JOB_NAME} -o=jsonpath='{.items[0].metadata.name}')
        kubectl logs ${LATEST_POD_NAME} -n my-realistic-app
        ```

---

## 5. DaemonSets

A **DaemonSet** ensures that all (or some) nodes in a cluster run a copy of a Pod. When new nodes are added to the cluster, Pods are automatically added to them. When nodes are removed from the cluster, those Pods are garbage collected.

### Why are they important?

* **Node-level utilities:** Ideal for deploying cluster-wide logging agents (e.g., Fluentd), monitoring agents (e.g., Prometheus Node Exporter), or storage daemons (e.g., Ceph).
* **Guaranteed Availability:** Ensures that a critical component is always running on every relevant node.

### How to Play Around:

1.  **Create a simple DaemonSet:**
    This will deploy a `busybox` pod that logs its hostname every 5 seconds to every node.
    ```yaml
    # my-daemonset.yaml
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      name: node-logger
      namespace: my-realistic-app
    spec:
      selector:
        matchLabels:
          app: node-logger
      template:
        metadata:
          labels:
            app: node-logger
        spec:
          tolerations: # Important for Kind to run on control-plane node too
          - key: node-role.kubernetes.io/control-plane
            operator: Exists
            effect: NoSchedule
          containers:
          - name: logger
            image: busybox:latest
            command: ["/bin/sh", "-c", "while true; do echo 'Hello from $(HOSTNAME)'; sleep 5; done"]
    ```
    * Apply the DaemonSet: `kubectl apply -f my-daemonset.yaml -n my-realistic-app`
    * Monitor DaemonSet: `kubectl get ds -n my-realistic-app`
    * Observe Pods (you should see one Pod per node): `kubectl get pods -l app=node-logger -o wide -n my-realistic-app`
    * Check logs from a specific DaemonSet Pod (get a pod name from the above command):
        ```bash
        kubectl logs <node-logger-pod-name> -n my-realistic-app
        ```
    * If you scale your Kind cluster by adding more worker nodes (requires cluster recreation or dynamic node addition if using a cloud provider feature), new DaemonSet Pods would automatically appear on them.

---

Feel free to experiment with these concepts by creating the YAML files, applying them to your Kind cluster, and observing their behavior using `kubectl` commands. Remember to clean up resources using `kubectl delete -f <your-yaml-file>` when you're done with an experiment.

Enjoy exploring!