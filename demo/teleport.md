# Prerequisites:
 1. GitHub account
 2. Oracle infrastructure created using provided terraform script
 3. Domain name registered, and subdomain configured to point to Access NLB

# Install Teleport 
    # Provide your email and access domain 
    export EMAIL="<your email>"
    export TELEPORT_HOST="access.<your domain>"
    
    # Disable firewalld (TODO: Create proper rules instead)  
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld

    # Install teleport, and enable the service
    sudo yum-config-manager --add-repo https://rpm.releases.teleport.dev/teleport.repo -y
    sudo yum install teleport -y
    sudo /usr/local/bin/teleport configure --acme --acme-email="${EMAIL}" --cluster-name="${TELEPORT_HOST}" | sudo tee /etc/teleport.yaml
    sudo systemctl enable teleport
    sudo systemctl start teleport

    # Create initial user
    sudo /usr/local/bin/tctl users add teleport-admin --roles=editor,access --logins=opc

# Show capabilities at this point:
1. Access ssh via UI
2. Upload files
3. Connection to another private server in the network
4. Access ssh via `tsh ssh`
5. Access ssh via `ssh`:
   1. `tsh config > ssh.cfg`
   2. `ssh opc@access.access.devopstech.ga -F ssh.cfg`
6. Add additional node to the cluster
7. Connect to new node via tsh ssh and ssh

# Add k8s cluster to teleport
*Full guide: https://goteleport.com/docs/kubernetes-access/guides/standalone-teleport/*

    # Make sure you have kubectl access:
    kubectl get pods -A

    # Download and run the preparation script: 
    cd /home/opc
    wget https://github.com/gravitational/teleport/raw/master/examples/k8s-auth/get-kubeconfig.sh
    chmod +x get-kubeconfig.sh
    ./get-kubeconfig.sh

    # Add k8s service to /etc/teleport.yaml:
    sudo echo '
    kubernetes_service:
      enabled: yes
      listen_addr: 0.0.0.0:3027
      kubeconfig_file: "/home/opc/kubeconfig"
    ' >> /etc/teleport.yaml
    sudo systemctl teleport reload

    # Create kubernetes-user role for k8s access: 
    # Use UI to upload the k8s-role.yaml
    # Or
    sudo /usr/local/bin/tctl create -f k8s-role.yaml

    # Add a role to teleport admin user
    # We will use UI this time

# Enable GitHub SSO
*Full guide: https://goteleport.com/docs/access-controls/sso/github-sso/*

1. Create Github org and a "dev" team in this org 
2. Cretate an OAuth application on your org
3. Fill values in lines marked with `# <<<` in `github.yml` and `cap.yml` files
4. Logout from UI and CLI
5. Login again with GitHub credentials