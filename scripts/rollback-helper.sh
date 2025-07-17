#!/bin/bash
# Rollback Helper Script for CarvedRock Catalog Service
# This script helps demonstrate rollback scenarios in the GitOps lab

echo "=== GitOps Rollback Helper ==="
echo "This script helps you understand rollback scenarios in GitOps"
echo ""

# Function to show current deployment status
show_status() {
    echo "Current Deployment Status:"
    kubectl get deployment catalog-service -o wide
    echo ""
    echo "Current Version:"
    kubectl describe deployment catalog-service | grep VERSION
    echo ""
    echo "ArgoCD Application Status:"
    argocd app get carvedrock-catalog --refresh
}

# Function to show sync history
show_history() {
    echo "ArgoCD Sync History:"
    argocd app history carvedrock-catalog
}

# Function to display menu
show_menu() {
    echo ""
    echo "Select an option:"
    echo "1) Show current deployment status"
    echo "2) Show ArgoCD sync history"
    echo "3) Trigger manual sync from Git"
    echo "4) Show differences between Git and cluster"
    echo "5) Exit"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            show_status
            ;;
        2)
            show_history
            ;;
        3)
            echo "Triggering manual sync..."
            argocd app sync carvedrock-catalog
            ;;
        4)
            echo "Showing differences between Git and live state:"
            argocd app diff carvedrock-catalog
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
