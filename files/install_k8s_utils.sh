#!/bin/bash

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

render_config(){
cat <<-EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<-EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

modprobe overlay
modprobe br_netfilter

sudo sysctl --system
}

preflight(){
    apt-get update && apt-get upgrade -y

    apt-get install -y \
        ca-certificates \
        unzip \
        software-properties-common \
        curl \
        gnupg \
        openssl \
        lsb-release \
        apt-transport-https \
        jq
    
    render_config
    
    # Disable firewall 
    /usr/sbin/netfilter-persistent stop
    /usr/sbin/netfilter-persistent flush

    systemctl stop netfilter-persistent.service
    systemctl disable netfilter-persistent.service
    # END Disable firewall
}

preflight_longhorn(){
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  open-iscsi curl util-linux nfs-common
    systemctl start iscsid.service
    systemctl enable iscsid.service
}

install_oci_cli(){
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  python3 python3-pip
  pip install oci-cli
}

setup_repos(){
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

    apt-get update
}

setup_cri(){
    apt-get update
    apt-get install -y containerd.io
    mkdir -p /etc/containerd
    cat /etc/containerd/config.toml | grep -Fx "[grpc]"
    res=$?
    if [ $res -ne 0 ]; then
        containerd config default | tee /etc/containerd/config.toml
    fi
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    systemctl restart containerd
    systemctl enable containerd
}

install_k8s_utils(){
    sleep 5
    apt-get update
    apt-get install -y kubelet=${k8s_version}* kubeadm=${k8s_version}* kubectl=${k8s_version}*
    apt-mark hold kubelet kubeadm kubectl
}

preflight
install_oci_cli
setup_repos
setup_cri
install_k8s_utils
%{ if install_longhorn }
preflight_longhorn
%{ endif }