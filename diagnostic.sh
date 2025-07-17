#!/bin/bash
# Diagnostic script to check GitOps lab environment

echo "=== GitOps Lab Diagnostic Script ==="
echo ""

# Function to check command availability
check_command() {
    if command -v $1 &> /dev/null; then
        echo "✓ $1 is installed"
    else
        echo "✗ $1 is NOT installed"
        return 1
    fi
}

# Function to check k3d cluster
check_k3d_cluster() {
    echo ""
    echo "=== Checking k3d cluster ==="
    if k3d cluster list 2>/dev/null | grep -q "gitops-lab"; then
        echo "✓ k3d cluster 'gitops-lab' exists"
        k3d cluster list
    else
        echo "✗ k3d cluster 'gitops-lab' does NOT exist"
        echo "  Run: k3d cluster create gitops-lab --api-port 6443 --servers 1 --agents 1 --port 30080:80@loadbalancer --wait"
        return 1
    fi
}

# Function to check kubernetes connectivity
check_kubernetes() {
    echo ""
    echo "=== Checking Kubernetes connectivity ==="
    if kubectl cluster-info &>/dev/null; then
        echo "✓ Kubernetes is accessible"
        kubectl get nodes
    else
        echo "✗ Cannot connect to Kubernetes"
        echo "  Check your kubeconfig: kubectl config current-context"
        return 1
    fi
}

# Function to check ArgoCD installation
check_argocd() {
    echo ""
    echo "=== Checking ArgoCD installation ==="
    
    # Check namespace
    if kubectl get namespace argocd &>/dev/null; then
        echo "✓ ArgoCD namespace exists"
    else
        echo "✗ ArgoCD namespace does NOT exist"
        echo "  Run: kubectl create namespace argocd"
        return 1
    fi
    
    # Check deployments
    echo ""
    echo "ArgoCD Deployments:"
    kubectl get deployments -n argocd
    
    # Check pods
    echo ""
    echo "ArgoCD Pods:"
    kubectl get pods -n argocd
    
    # Check services
    echo ""
    echo "ArgoCD Services:"
    kubectl get svc -n argocd
    
    # Check for admin secret
    if kubectl get secret argocd-initial-admin-secret -n argocd &>/dev/null; then
        echo ""
        echo "✓ ArgoCD admin secret exists"
        echo "Admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
    else
        echo ""
        echo "✗ ArgoCD admin secret does NOT exist"
    fi
}

# Function to check port availability
check_ports() {
    echo ""
    echo "=== Checking port availability ==="
    
    for port in 8080 8081 8082 6443; do
        if lsof -i :$port &>/dev/null; then
            echo "✗ Port $port is in use by:"
            lsof -i :$port | grep LISTEN
        else
            echo "✓ Port $port is available"
        fi
    done
}

# Function to kill interfering processes
kill_interfering_processes() {
    echo ""
    echo "=== Checking for interfering processes ==="
    
    # Check for memcached
    if pgrep memcached >/dev/null; then
        echo "Found memcached processes that may be causing errors"
        echo "Kill them? (y/n)"
        read -r response
        if [[ "$response" == "y" ]]; then
            pkill memcached
            echo "✓ Killed memcached processes"
        fi
    fi
}

# Main diagnostic flow
echo "=== Starting diagnostics ==="
echo ""

echo "1. Checking required commands:"
check_command docker
check_command k3d
check_command kubectl
check_command argocd

echo ""
echo "2. Checking system:"
kill_interfering_processes
check_ports

echo ""
echo "3. Checking k3d cluster:"
check_k3d_cluster

echo ""
echo "4. Checking Kubernetes:"
check_kubernetes

echo ""
echo "5. Checking ArgoCD:"
check_argocd

echo ""
echo "=== Diagnostic complete ==="
echo ""
echo "If you see any ✗ marks above, those items need to be fixed."
echo ""
echo "To start fresh:"
echo "1. k3d cluster delete gitops-lab"
echo "2. Run the setup.sh script again"
echo ""
echo "To access ArgoCD after everything is running:"
echo "kubectl port-forward svc/argocd-server -n argocd 8081:443 &"
echo "(Note: using port 8081 to avoid conflicts with port 8080)"
