# Define registry name and port
reg_name='kind-registry'
reg_port='5001' # Using 5001 to avoid conflicts with other services potentially on 5000

# 1. Create registry container unless it already exists
# This ensures a clean state for the registry.
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" \
    --network bridge --name "${reg_name}" \
    registry:2
fi

# 2. Delete any existing Kind cluster to ensure a clean setup for new config
kind delete cluster --name k8s-poc-cluster || true # Use || true to ignore errors if cluster doesn't exist

# 3. Create Kind cluster with containerd registry config dir enabled
# This tells Kind to look for registry configuration files on the node.
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: k8s-poc-cluster
# Configure containerd to look for registry configuration files
# Configure containerd to look for registry configuration files and insecure mirrors
containerdConfigPatches:
- |- # This patch configures containerd to treat localhost:5001 as an insecure HTTP registry
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5001"]
      endpoint = ["http://localhost:5001"] # Explicitly tell containerd to use HTTP for this endpoint
- |- # This patch sets the path for containerd's registry configuration files
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
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
# Worker nodes (no direct port mappings for registry needed on workers here,
# as containerd config will handle internal routing)
- role: worker
- role: worker
EOF

# 4. Add the registry config to the nodes
# This is crucial for Kind nodes to correctly resolve 'localhost:5001' to the registry container.
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"] # Registry container is accessed by its name on the Kind network
EOF
done

# 5. Connect the registry to the cluster network if not already connected
# This ensures Kind nodes and the registry are on the same Docker network.
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# 6. Document the local registry in Kubernetes (optional, but good practice for tooling)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF