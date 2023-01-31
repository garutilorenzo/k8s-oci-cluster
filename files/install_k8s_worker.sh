#!/bin/bash

render_kubejoin(){

HOSTNAME=$(hostname)
ADVERTISE_ADDR=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
hash_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" ==  "${hash_secret_name}-${environment}") | .id')
token_ocid=$(oci vault secret list --compartment-id ${compartment_ocid} | jq -r '.data[] | select(."secret-name" == "${token_secret_name}-${environment}") | .id')

CA_HASH=$(oci vault secret get --secret-id $hash_ocid | base64 -d)
KUBEADM_TOKEN=$(oci vault secret get --secret-id $token_ocid | base64 -d)

cat <<-EOF > /root/kubeadm-join-worker.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $KUBEADM_TOKEN
    apiServerEndpoint: ${control_plane_url}:${kube_api_port}
    caCertHashes: 
      - sha256:$CA_HASH
localAPIEndpoint:
  advertiseAddress: $ADVERTISE_ADDR
  bindPort: ${kube_api_port}
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

k8s_join(){
  kubeadm join --ignore-preflight-errors=NumCPU --config /root/kubeadm-join-worker.yaml
}

proxy_protocol_stuff(){
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python3 python3-pip nginx
systemctl enable nginx
pip install oci-cli

cat << 'EOF' > /root/find_ips.sh
export OCI_CLI_AUTH=instance_principal
private_ips=()
# Fetch the OCID of all the running instances in OCI and store to an array
instance_ocids=$(oci search resource structured-search --query-text "QUERY instance resources where lifeCycleState='RUNNING'"  --query 'data.items[*].identifier' --raw-output | jq -r '.[]' ) 
# Iterate through the array to fetch details of each instance one by one
for val in $${instance_ocids[@]} ; do
  
  echo $val
  # Get name of the instance
  instance_name=$(oci compute instance get --instance-id $val --raw-output --query 'data."display-name"')
  echo $instance_name
  # Get Public Ip of the instance
  public_ip=$(oci compute instance list-vnics --instance-id $val --raw-output --query 'data[0]."public-ip"')
  echo $public_ip
  private_ip=$(oci compute instance list-vnics --instance-id $val --raw-output --query 'data[0]."private-ip"')
  echo $private_ip
  private_ips+=($private_ip)
done
for i in "$${private_ips[@]}"
do
  echo "$i" >> /tmp/private_ips
done
EOF

NGINX_MODULE=/usr/lib/nginx/modules/ngx_stream_module.so
NGINX_USER=www-data

cat << EOD > /root/nginx-header.tpl
load_module $NGINX_MODULE;
user $NGINX_USER;
worker_processes auto;
pid /run/nginx.pid;
EOD

cat << 'EOF' > /root/nginx-footer.tpl
events {
  worker_connections 768;
  # multi_accept on;
}
stream {
  upstream k3s-http {
    {% for private_ip in private_ips -%}
    server {{ private_ip }}:${ingress_controller_http_nodeport} max_fails=3 fail_timeout=10s;
    {% endfor -%}
  }
  upstream k3s-https {
    {% for private_ip in private_ips -%}
    server {{ private_ip }}:${ingress_controller_https_nodeport} max_fails=3 fail_timeout=10s;
    {% endfor -%}
  }
  log_format basic '$remote_addr [$time_local] '
    '$protocol $status $bytes_sent $bytes_received '
    '$session_time "$upstream_addr" '
    '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
  access_log /var/log/nginx/k3s_access.log basic;
  error_log  /var/log/nginx/k3s_error.log;
  proxy_protocol on;
  server {
    listen ${https_lb_port};
    proxy_pass k3s-https;
    proxy_next_upstream on;
  }
  server {
    listen ${http_lb_port};
    proxy_pass k3s-http;
    proxy_next_upstream on;
  }
}
EOF

cat /root/nginx-header.tpl /root/nginx-footer.tpl > /root/nginx.tpl

cat << 'EOF' > /root/render_nginx_config.py
from jinja2 import Template
import os
RAW_IP = open('/tmp/private_ips', 'r').readlines()
IPS = [i.replace('\n','') for i in RAW_IP]
nginx_config_template_path = '/root/nginx.tpl'
nginx_config_path = '/etc/nginx/nginx.conf'
with open(nginx_config_template_path, 'r') as handle:
    nginx_config_template = handle.read()
new_nginx_config = Template(nginx_config_template).render(
    private_ips = IPS
)
with open(nginx_config_path, 'w') as handle:
    handle.write(new_nginx_config)
EOF

chmod +x /root/find_ips.sh
./root/find_ips.sh

python3 /root/render_nginx_config.py

nginx -t

systemctl restart nginx
}

until $(curl -k --output /dev/null --silent --head -X GET https://${control_plane_url}:${kube_api_port}); do
  printf '.'
  sleep 5
done

export OCI_CLI_AUTH=instance_principal
render_kubejoin
k8s_join
%{ if install_nginx_ingress }
proxy_protocol_stuff
%{ endif }
%{ if install_longhorn }
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  open-iscsi curl util-linux
%{ endif }