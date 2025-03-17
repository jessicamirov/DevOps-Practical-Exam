#!/bin/bash
set -e

# Variables
CHART_NAME="flask-aws-monitor"
RELEASE_NAME="flask-monitor"
NAMESPACE="default"
DOCKERHUB_USERNAME="your-dockerhub-username"  # Replace with your DockerHub username

# Check if kubectl is connected to a cluster
echo "Checking Kubernetes connection..."
if ! kubectl get nodes &> /dev/null; then
  echo "Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig."
  exit 1
fi
echo "Connected to Kubernetes cluster:"
kubectl get nodes

# Create AWS credentials secret (if not using the template)
echo "Creating AWS credentials secret..."
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -sp "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo

kubectl create secret generic aws-credentials \
  --from-literal=access-key=$AWS_ACCESS_KEY_ID \
  --from-literal=secret-key=$AWS_SECRET_ACCESS_KEY \
  --dry-run=client -o yaml | kubectl apply -f -

# Update the image repository in values.yaml
echo "Updating Docker image repository in values.yaml..."
sed -i "s/your-dockerhub-username/$DOCKERHUB_USERNAME/g" values.yaml

# Verify the Helm chart
echo "Verifying Helm chart..."
helm lint .

# Install the Helm chart
echo "Installing Helm chart..."
helm install $RELEASE_NAME . \
  --namespace $NAMESPACE \
  --set image.repository=$DOCKERHUB_USERNAME/flask-aws-monitor \
  --set image.tag=latest

# Wait for deployment to become ready
echo "Waiting for deployment to become ready..."
kubectl rollout status deployment/$RELEASE_NAME-$CHART_NAME --namespace $NAMESPACE

# Get service information
echo "Service information:"
kubectl get svc $RELEASE_NAME-$CHART_NAME --namespace $NAMESPACE

# If service type is LoadBalancer, wait for external IP
if kubectl get svc $RELEASE_NAME-$CHART_NAME --namespace $NAMESPACE -o jsonpath='{.spec.type}' | grep -q "LoadBalancer"; then
  echo "Waiting for LoadBalancer external IP..."
  
  EXTERNAL_IP=""
  while [ -z "$EXTERNAL_IP" ]; do
    EXTERNAL_IP=$(kubectl get svc $RELEASE_NAME-$CHART_NAME --namespace $NAMESPACE --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    if [ -z "$EXTERNAL_IP" ]; then
      echo "Waiting for external IP..."
      sleep 10
    fi
  done
  
  echo "Application is accessible at: http://$EXTERNAL_IP:80"
  echo "To test the application, run: curl http://$EXTERNAL_IP:80/health"
else
  echo "Service is not of type LoadBalancer. Access it via Kubernetes port-forwarding:"
  echo "kubectl port-forward svc/$RELEASE_NAME-$CHART_NAME 8080:80 --namespace $NAMESPACE"
  echo "Then access it at: http://localhost:8080"
fi

echo -e "\nHelm deployment completed successfully!"
echo "To upgrade the chart in the future, use:"
echo "helm upgrade $RELEASE_NAME . --namespace $NAMESPACE"
echo "To rollback to a previous revision, use:"
echo "helm rollback $RELEASE_NAME [REVISION] --namespace $NAMESPACE"
echo "To uninstall the chart, use:"
echo "helm uninstall $RELEASE_NAME --namespace $NAMESPACE"