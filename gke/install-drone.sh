#!/usr/bin/env bash
kernel_name=$(uname -s)
kubectl cluster-info > /dev/null 2>&1
if [ $? -eq 1 ]
then
  echo "kubectl was unable to reach your Kubernetes cluster. Make sure that" \
       "you have selected one using the 'gcloud container' commands."
  exit 1
fi

# Clear out any existing configmap. Fail silently if there are none to delete.
kubectl delete namspace drone 2> /dev/null
if [ $? -eq 1 ]
then
  echo "Before continuing, you should have followed the prep work outlined" \
       "in the README.md file in this directory. You should have an existing" \
       "Kubernetes cluster and an EBS volume in the same AZ. You should have" \
       "also edited drone-configmap.yaml and drone-server-deployment.yaml as directed."
  echo
  read -p "<Press enter once you've made your edits>"
fi

echo "Create drone namespace..."
kubectl create -f drone-namespace.yaml 2> /dev/null

echo "Randomly generating secrets and uploading..."
if [ "$kernel_name" == "Darwin" ]; then
  drone_token=`openssl rand -base64 8 | md5 | head -c8; echo`
else
  drone_token=`cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
fi
b64_drone_token=`echo $drone_token | base64`
[ "$kernel_name" == "Darwin" ] && sed -e "s/REPLACE-THIS-WITH-BASE64-ENCODED-VALUE/${b64_drone_token}/g" -i "" drone-secret.yaml
[ "$kernel_name" == "Linux" ] && sed -e "s/REPLACE-THIS-WITH-BASE64-ENCODED-VALUE/${b64_drone_token}/g" -i drone-secret.yaml
kubectl create -f drone-secret.yaml
kubectl create -f drone-configmap.yaml
kubectl create -f drone-server-deployment.yaml
kubectl create -f drone-server-service.yaml 2> /dev/null
if [ $? -eq 0 ]
then
  echo "Since this is your first time running this script, we have created a" \
       "front-facing Load Balancer (ELB). You'll need to wait" \
       "for the LB to initialize and be assigned a hostname. We'll pause for a" \
       "bit and walk you through this after the break."
  while true; do
    echo "Waiting for 40 seconds for ELB hostname assignment..."
    sleep 40
    echo "[[ Querying your drone-server service to see if it has a hostname yet... ]]"
    echo
    kubectl describe svc drone-service --namespace=drone
    echo "[[ Query complete. ]]"
    read -p "Do you see a 'Loadbalancer Ingress' field with a value above? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "We'll give it some more time.";;
        * ) echo "No idea what that was, but we'll assume yes!";;
    esac
  done
  echo
  echo "Excellent. This will be the hostname that you can create a DNS (CNAME)"
  echo "record for, or point your browser at directly."
  read -p "<Press enter to proceed once you have noted your ELB's hostname>"
fi

echo
echo "===== Drone Server installed ============================================"
echo "Your cluster is now downloading the Docker image for Drone Server."
echo "You can check the progress of this by typing 'kubectl get pods' in another"
echo "tab. Once you see 1/1 READY for your drone-server-* pod, point your browser"
echo "at http://<your-elb-hostname-here> and you should see a login page."
echo
read -p "<Press enter once you've verified that your Drone Server is up>"
echo
echo "===== Drone Agent installation =========================================="
kubectl create -f drone-agent-deployment.yaml
echo "Your cluster is now downloading the Docker image for Drone Agent."
echo "You can check the progress of this by typing 'kubectl get pods'"
echo "Once you see 1/1 READY for your drone-agent-* pod, your Agent is ready"
echo "to start pulling and running builds."
echo
read -p "<Press enter once you've verified that your Drone Agent is up>"
echo
echo "===== Post-installation tasks ==========================================="
echo "At this point, you should have a fully-functional Drone install. If this"
echo "Is not the case, stop by either of the following for help:"
echo
echo "  * Discussion Site, help category: https://discuss.drone.io/"
echo
echo "You'll also want to read the documentation: https://docs.drone.io"
