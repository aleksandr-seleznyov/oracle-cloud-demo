# ALL Servers expected to be Oracle Linux 8.x


# Teleport host
export EMAIL="<your email>"
export TELEPORT_HOST="access.<your domain>"

sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo yum-config-manager --add-repo https://rpm.releases.teleport.dev/teleport.repo -y
sudo yum install teleport -y
sudo /usr/local/bin/teleport configure --acme --acme-email="${EMAIL}" --cluster-name="${TELEPORT_HOST}" | sudo tee /etc/teleport.yaml
sudo systemctl enable teleport
sudo systemctl start teleport
sudo /usr/local/bin/tctl users add teleport-admin --roles=editor,access --logins=opc

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl





# k8s-master
sudo systemctl stop firewalld
sudo systemctl disable firewalld
curl -sfL https://get.k3s.io | sh -
# Get token:
# sudo cat /var/lib/rancher/k3s/server/node-token
# Save it for the future use

# Get kubeconfig
# sudo cat /etc/rancher/k3s/k3s.yaml
# Save it for the future use



# k8s-node
sudo systemctl stop firewalld
sudo systemctl disable firewalld
export TOKEN= #Paste token from the master node
curl -sfL https://get.k3s.io | K3S_URL=https://k8s-master:6443 K3S_TOKEN="${TOKEN}" sh -
