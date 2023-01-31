#!/bin/bash

render_kubeinit(){

HOSTNAME=$(hostname)
ADVERTISE_ADDR=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')

cat <<-EOF > /root/kubeadm-init-config.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $ADVERTISE_ADDR
  bindPort: ${kube_api_port }
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: $HOSTNAME
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: ${cluster_name}
controllerManager: {}
dns: {}
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: ${k8s_version}
controlPlaneEndpoint: ${control_plane_ip}:${kube_api_port }
networking:
  dnsDomain: ${k8s_dns_domain}
  podSubnet: ${k8s_pod_subnet}
  serviceSubnet: ${k8s_service_subnet}
scheduler: {}
etcd:
  local:
    dataDir: /var/lib/etcd
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF
}

wait_for_pods(){
  until kubectl get pods -A | grep 'Running'; do
    echo 'Waiting for k8s startup'
    sleep 5
  done
}

wait_for_masters(){
  until kubectl get nodes -o wide | grep 'control-plane,master'; do
    echo 'Waiting for k8s control-planes'
    sleep 5
  done
}

setup_env(){
  until [ -f /etc/kubernetes/admin.conf ]
  do
    sleep 5
  done
  echo "K8s initialized"
  export KUBECONFIG=/etc/kubernetes/admin.conf
}

render_kubejoin(){

HOSTNAME=$(hostname)
ADVERTISE_ADDR=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
hash_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" ==  "${hash_secret_name}-${environment}" and ."lifecycle-state" == "ACTIVE") | .id')
token_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" == "${token_secret_name}-${environment}" and ."lifecycle-state" == "ACTIVE") | .id')
cert_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" == "${cert_secret_name}-${environment}" and ."lifecycle-state" == "ACTIVE") | .id')

hash_default_value="empty hash secret"
token_default_value="empty token secret"
cert_default_value="empty cert secret"

CA_HASH=$(oci secrets secret-bundle get --secret-id --secret-id $hash_ocid | jq -r '.data | ."secret-bundle-content" | .content' | base64 -d)
KUBEADM_TOKEN=$(oci secrets secret-bundle get --secret-id --secret-id $token_ocid | jq -r '.data | ."secret-bundle-content" | .content' | base64 -d)
KUBEADM_CERT=$(oci secrets secret-bundle get --secret-id $cert_ocid | jq -r '.data | ."secret-bundle-content" | .content' | base64 -d)

until [ "$CA_HASH" != "$hash_default_value" ]
do
  echo "CA not updated.."
  echo "wait 10 seconds"
  sleep 10
  CA_HASH=$(oci secrets secret-bundle get --secret-id $hash_ocid | jq -r '.data | ."secret-bundle-content" | .content' | base64 -d)
  echo $CA_HASH
done

until [ "$KUBEADM_TOKEN" != "$token_default_value" ]
do
  echo "Kubeadm token not updated.."
  echo "wait 10 seconds"
  sleep 10
  KUBEADM_TOKEN=$(oci secrets secret-bundle get --secret-id --secret-id $token_ocid | jq -r '.data | ."secret-bundle-content" | .content' | base64 -d)
  echo $KUBEADM_TOKEN
done

until [ "$KUBEADM_CERT" != "$cert_default_value" ]
do
  echo "Kubeadm cert not updated.."
  echo "wait 10 seconds"
  sleep 10
  KUBEADM_CERT=$(oci secrets secret-bundle get --secret-id $cert_ocid | jq -r '.data | ."secret-bundle-content" | .content' | base64 -d)
  echo $KUBEADM_CERT
done

cat <<-EOF > /root/kubeadm-join-master.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $KUBEADM_TOKEN
    apiServerEndpoint: ${control_plane_ip}:${kube_api_port}
    caCertHashes: 
      - sha256:$CA_HASH
controlPlane:
  localAPIEndpoint:
    advertiseAddress: $ADVERTISE_ADDR
    bindPort: ${kube_api_port}
  certificateKey: $KUBEADM_CERT
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: $HOSTNAME
  taints: null
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF
}

render_nginx_config(){
cat << 'EOF' > "$NGINX_RESOURCES_FILE"
---
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller-loadbalancer
  namespace: ingress-nginx
spec:
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: 80
      nodePort: ${ingress_controller_http_nodeport}
    - name: https
      port: 443
      protocol: TCP
      targetPort: 443
      nodePort: ${ingress_controller_https_nodeport}
  type: NodePort
---
apiVersion: v1
data:
  allow-snippet-annotations: "true"
  enable-real-ip: "true"
  proxy-real-ip-cidr: "0.0.0.0/0"
  proxy-body-size: "20m"
  use-proxy-protocol: "true"
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: ${nginx_ingress_release}
  name: ingress-nginx-controller
  namespace: ingress-nginx
EOF
}

render_longhorn_config(){
cat << 'EOF' > "$LONGHORN_RESOURCES_FILE"
---
# Builtin: "helm template" does not respect --create-namespace
apiVersion: v1
kind: Namespace
metadata:
  name: longhorn-system
---
# Source: longhorn/templates/default-setting.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: longhorn-default-setting
  namespace: longhorn-system
  labels:
    app.kubernetes.io/name: longhorn
    app.kubernetes.io/instance: longhorn
    app.kubernetes.io/version: ${longhorn_release}
data:
  default-setting.yaml: |-
    guaranteed-engine-manager-cpu: 0
    guaranteed-replica-manager-cpu: 0
EOF
}

install_and_configure_longhorn(){
  LONGHORN_RESOURCES_FILE=/root/longhorn-ingress-resources.yaml
  render_longhorn_config
  kubectl apply -f $LONGHORN_RESOURCES_FILE
  kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${longhorn_release}/deploy/longhorn.yaml
}

install_and_configure_nginx(){
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${nginx_ingress_release}/deploy/static/provider/baremetal/deploy.yaml
  NGINX_RESOURCES_FILE=/root/nginx-ingress-resources.yaml
  render_nginx_config
  kubectl apply -f $NGINX_RESOURCES_FILE
}

k8s_join(){
  kubeadm join --ignore-preflight-errors=NumCPU --config /root/kubeadm-join-master.yaml
  mkdir ~/.kube
  cp /etc/kubernetes/admin.conf ~/.kube/config
}

generate_vault_secrets(){
  HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
  HASH_BASE64=$(echo $HASH | base64 -w0)
  echo $HASH > /tmp/ca.txt

  TOKEN=$(kubeadm token create)
  echo $TOKEN > /tmp/kubeadm_token.txt
  TOKEN_BASE64=$(echo $TOKEN | base64 -w0)

  CERT=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)
  echo $CERT > /tmp/kubeadm_cert.txt
  CERT_BASE64=$(echo $CERT | base64 -w0)

  hash_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" ==  "${hash_secret_name}-${environment}" and ."lifecycle-state" == "ACTIVE") | .id')
  token_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" == "${token_secret_name}-${environment}") and ."lifecycle-state" == "ACTIVE") | .id')
  cert_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" == "${cert_secret_name}-${environment}") and ."lifecycle-state" == "ACTIVE") | .id')
  
  oci vault secret update-base64 --secret-id $hash_ocid  --secret-content-content $HASH_BASE64
  oci vault secret update-base64 --secret-id $token_ocid --secret-content-content $TOKEN
  oci vault secret update-base64 --secret-id $cert_ocid  --secret-content-content $CERT_BASE64
}

k8s_init(){
  # # Workaround
  # crictl pull k8s.gcr.io/coredns/coredns:v1.9.3
  # ctr --namespace=k8s.io image tag k8s.gcr.io/coredns/coredns:v1.9.3 k8s.gcr.io/coredns:v1.9.3
  
  kubeadm init --ignore-preflight-errors=NumCPU --config /root/kubeadm-init-config.yaml
  mkdir ~/.kube
  cp /etc/kubernetes/admin.conf ~/.kube/config
}

setup_cni(){
  kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
}

export OCI_CLI_AUTH=instance_principal
first_instance=$(oci compute instance list --compartment-id ${compartment_ocid} --availability-domain ${availability_domain} --lifecycle-state RUNNING --sort-by TIMECREATED  | jq -r '.data[]|select(."display-name" | endswith("k8s-servers")) | .["display-name"]' | tail -n 1)
instance_id=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance | jq -r '.displayName')
control_plane_status=$(curl --connect-timeout 10 -o /dev/null -L -k -s -w '%%{http_code}' https://${control_plane_ip}:${kube_api_port})

if [[ "$first_instance" == "$instance_id" ]] && [[ "$control_plane_status" -ne 403 ]]; then
  render_kubeinit
  k8s_init
  setup_env
  wait_for_pods
  setup_cni
  generate_vault_secrets
  echo "Wait 180 seconds for control-planes to join"
  sleep 180
  wait_for_masters
  %{ if install_nginx_ingress }
  install_and_configure_nginx
  %{ endif }
  %{ if install_longhorn }
  install_and_configure_longhorn
  %{ endif }
  # Make Master nodes schedulable since we have only 4 nodes
  kubectl taint nodes --all node-role.kubernetes.io/master-
else
  render_kubejoin
  k8s_join
fi