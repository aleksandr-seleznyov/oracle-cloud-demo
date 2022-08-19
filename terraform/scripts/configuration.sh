# ALL Servers expected to be Oracle Linux 8.x
# Teleport host
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo iptables -I FORWARD  -s 10.0.0.0/16 -j ACCEPT
sudo iptables -I FORWARD  -d 10.0.0.0/16 -j ACCEPT
sudo iptables -I INPUT -s 10.0.0.0/16 -j ACCEPT
sudo iptables -I INPUT  -d 10.0.0.0/16 -j ACCEPT
sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT


#K8S Nodes
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo iptables -I FORWARD  -s 10.0.0.0/8 -j ACCEPT
sudo iptables -I FORWARD  -d 10.0.0.0/8 -j ACCEPT
sudo iptables -I INPUT -s 10.0.0.0/8 -j ACCEPT
sudo iptables -I INPUT  -d 10.0.0.0/8 -j ACCEPT
sudo iptables -I INPUT -p udp -m udp  -d 10.0.0.0/8  -j ACCEPT
sudo iptables -I FORWARD -p udp -m udp  -s 10.0.0.0/8  -j ACCEPT
sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT


#Install teleport master (amd64)
sudo yum-config-manager --add-repo https://rpm.releases.teleport.dev/teleport.repo
sudo yum install teleport
sudo /usr/local/bin/teleport configure --acme --acme-email=<your email> --cluster-name=access.<your domain> -o file
sudo systemctl start teleport
sudo systemctl enable teleport

# k8s-master
curl -sfL https://get.k3s.io | sh -


# k8s-node
curl -sfL https://get.k3s.io | K3S_URL=https://k8s-master:6443 K3S_TOKEN=<TOKEN FROM K8S MASTER HOST> sh -
