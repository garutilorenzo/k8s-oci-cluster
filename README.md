[![Wordpress CI](https://github.com/garutilorenzo/k8s-oci-cluster/actions/workflows/ci.yml/badge.svg)](https://github.com/garutilorenzo/k8s-oci-cluster/actions/workflows/ci.yml)
[![GitHub issues](https://img.shields.io/github/issues/garutilorenzo/k8s-oci-cluster)](https://github.com/garutilorenzo/k8s-oci-cluster/issues)
![GitHub](https://img.shields.io/github/license/garutilorenzo/k8s-oci-cluster)
[![GitHub forks](https://img.shields.io/github/forks/garutilorenzo/k8s-oci-cluster)](https://github.com/garutilorenzo/k8s-oci-cluster/network)
[![GitHub stars](https://img.shields.io/github/stars/garutilorenzo/k8s-oci-cluster)](https://github.com/garutilorenzo/k8s-oci-cluster/stargazers)

<p align="center">
  <img src="https://garutilorenzo.github.io/images/k8s-logo.png?" alt="k8s Logo"/>
</p>

# Deploy Kubernetes on Oracle Cloud Infrastructure (OCI)

Deploy a Kubernetes cluster for free, with kubeadm and Oracle [always free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) resources.

This project is based on the [OCI K3s cluster](https://github.com/garutilorenzo/k3s-oci-cluster) repository. The final result is the same, but in this repo  kubeadm is used to install the official Kubernetes release. For more information read [Kubernetes setup](#kubernetes-setup).

# Table of Contents

* [Important notes](#important-notes)
* [Requirements](#requirements)
* [Example RSA key generation](#example-rsa-key-generation)
* [Project setup](#project-setup)
* [Oracle provider setup](#oracle-provider-setup)
* [Pre flight checklist](#pre-flight-checklist)
* [Notes about OCI always free resources](#notes-about-oci-always-free-resources)
* [Infrastructure overview](#infrastructure-overview)
* [Kubernetes setup](#kubernetes-setup)
* [Deploy](#deploy)
* [Deploy a sample stack](#deploy-a-sample-stack)
* [Clean up](#clean-up)

**Note** choose a region with enough ARM capacity

### Important notes

* This is repo shows only how to use terraform with the Oracle Cloud infrastructure and use only the **always free** resources. This examples are **not** for a production environment.
* At the end of your trial period (30 days). All the paid resources deployed will be stopped/terminated
* At the end of your trial period (30 days), if you have a running compute instance it will be stopped/hibernated

### Requirements

To use this repo you will need:

* an Oracle Cloud account. You can register [here](https://cloud.oracle.com)

Once you get the account, follow the *Before you begin* and *1. Prepare* step in [this](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm) document.

#### Example RSA key generation

To use terraform with the Oracle Cloud infrastructure you need to generate an RSA key. Generate the rsa key with:

```
openssl genrsa -out ~/.oci/<your_name>-oracle-cloud.pem 4096
chmod 600 ~/.oci/<your_name>-oracle-cloud.pem
openssl rsa -pubout -in ~/.oci/<your_name>-oracle-cloud.pem -out ~/.oci/<your_name>-oracle-cloud_public.pem
```

replace *<your_name>* with your name or a string you prefer.

**NOTE** ~/.oci/<your_name>-oracle-cloud_public.pem this string will be used on the *terraform.tfvars* used by the Oracle provider plugin, so please take note of this string.

### Project setup

Clone this repo and go in the *example/* directory:

```
git clone https://github.com/garutilorenzo/k8s-oci-cluster.git
cd k8s-oci-cluster/example/
```

Now you have to edit the *main.tf* file and you have to create the *terraform.tfvars* file. For more detail see [Oracle provider setup](#oracle-provider-setup) and [Pre flight checklist](#pre-flight-checklist).

Or if you prefer you can create an new empty directory in your workspace and create this three files:

* terraform.tfvars - More details in [Oracle provider setup](#oracle-provider-setup)
* main.tf
* provider.tf

The main.tf file will look like:


```
variable "compartment_ocid" {

}

variable "tenancy_ocid" {

}

variable "user_ocid" {

}

variable "fingerprint" {

}

variable "private_key_path" {

}

variable "region" {
  default = "<change_me>"
}

module "k8s_cluster" {
  PATH_TO_PUBLIC_KEY     = "<change_me>"
  PATH_TO_PRIVATE_KEY    = "<change_me>"
  region                 = var.region
  availability_domain    = "<change_me>"
  compartment_ocid       = var.compartment_ocid
  my_public_ip_cidr      = "<change_me>"
  environment            = "staging"
  uuid                   = "<change_me>"
  install_longhorn       = true
  install_nginx_ingress  = true
  source                 = "github.com/garutilorenzo/k8s-oci-cluster"
}

output "k8s_servers_ips" {
  value = module.k8s_cluster.k8s_servers_ips
}

output "k8s_workers_ips" {
  value = module.k8s_cluster.k8s_workers_ips
}

output "public_lb_ip" {
  value = module.k8s_cluster.public_lb_ip
}
```

For all the possible variables see [Pre flight checklist](#pre-flight-checklist)

The provider.tf will look like:

```
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}
```

Now we can init terraform with:

```
terraform init

terraform init
Initializing modules...
Downloading git::https://github.com/garutilorenzo/k8s-oci-cluster.git for k8s_cluster...
- k8s_cluster in .terraform/modules/k8s_cluster

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/oci from the dependency lock file
- Reusing previous version of hashicorp/template from the dependency lock file
- Using previously-installed hashicorp/template v2.2.0
- Using previously-installed hashicorp/oci v4.64.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Oracle provider setup

In the *example/* directory of this repo you need to create a terraform.tfvars file, the file will look like:

```
fingerprint      = "<rsa_key_fingerprint>"
private_key_path = "~/.oci/<your_name>-oracle-cloud_public.pem"
user_ocid        = "<user_ocid>"
tenancy_ocid     = "<tenency_ocid>"
compartment_ocid = "<compartment_ocid>"
```

To find your tenency_ocid in the Ocacle Cloud console go to: Governance and Administration > Tenency details, then copy the OCID.

To find you user_ocid in the Ocacle Cloud console go to User setting (click on the icon in the top right corner, then click on User settings), click your username and then copy the OCID

The compartment_ocid is the same as tenency_ocid.

The fingerprint is the fingerprint of your RSA key, you can find this vale under User setting > API Keys

### Pre flight checklist

Once you have created the terraform.tfvars file edit the main.tf file (always in the *example/* directory) and set the following variables:

| Var   | Required | Desc |
| ------- | ------- | ----------- |
| `region`       | `yes`       | set the correct OCI region based on your needs  |
| `availability_domain` | `yes`        | Set the correct availability domain. See [how](#how-to-find-the-availability-doamin-name) to find the availability domain|
| `compartment_ocid` | `yes`        | Set the correct compartment ocid. See [how](#oracle-provider-setup) to find the compartment ocid |
| `my_public_ip_cidr` | `yes`        |  your public ip in cidr format (Example: 195.102.xxx.xxx/32) |
| `environment`  | `yes`  | Current work environment (Example: staging/dev/prod). This value is used for tag all the deployed resources |
| `compute_shape`  | `no`  | Compute shape to use. Default VM.Standard.A1.Flex. **NOTE** Is mandatory to use this compute shape for provision 4 always free VMs |
| `os_image_id`  | `no`  | Image id to use. Default image: Canonical-Ubuntu-20.04-aarch64-2022.01.18-0. See [how](#how-to-list-all-the-os-images) to list all available OS images |
| `oci_core_vcn_dns_label`  | `no`  | VCN DNS label. Default: defaultvcn |
| `oci_core_subnet_dns_label10`  | `no`  | First subnet DNS label. Default: defaultsubnet10 |
| `oci_core_subnet_dns_label11`  | `no`  | Second subnet DNS label. Default: defaultsubnet11 |
| `oci_core_vcn_cidr`  | `no`  | VCN CIDR. Default: oci_core_vcn_cidr |
| `oci_core_subnet_cidr10`  | `no`  | First subnet CIDR. Default: 10.0.0.0/24 |
| `oci_core_subnet_cidr11`  | `no`  | Second subnet CIDR. Default: 10.0.1.0/24 |
| `oci_identity_dynamic_group_name`  | `no`  | Dynamic group name. This dynamic group will contains all the instances of this specific compartment. Default: Compute_Dynamic_Group |
| `oci_identity_policy_name`  | `no`  | Policy name. This policy will allow dynamic group 'oci_identity_dynamic_group_name' to read OCI api without auth. Default: Compute_To_Oci_Api_Policy |
| `k8s_load_balancer_name`  | `no`  | Internal LB name. Default: k8s internal load balancer  |
| `public_load_balancer_name`  | `no`  | Public LB name. Default: k8s public LB  |
| `k8s_version`  | `no`  | Kubernetes version to install  |
| `k8s_pod_subnet`  | `no`  | Kubernetes pod subnet managed by the CNI (Flannel). Default: 10.244.0.0/16 |
| `k8s_service_subnet`  | `no`  | Kubernetes pod service managed by the CNI (Flannel). Default: 10.96.0.0/12 |
| `k8s_dns_domain`  | `no`  | Internal kubernetes DNS domain. Default: cluster.local |
| `kube_api_port`  | `no`  | Kube api default port Default: 6443  |
| `public_lb_shape`  | `no`  | LB shape for the public LB. Default: flexible. **NOTE** is mandatory to use this kind of shape to provision two always free LB (public and private)  |
| `http_lb_port`  | `no`  | http port used by the public LB. Default: 80  |
| `https_lb_port`  | `no`  | http port used by the public LB. Default: 443  |
| `extlb_listener_http_port`  | `no`  | HTTP nodeport where nginx ingress controller will listen. Default: 30080 |
| `extlb_listener_https_port`  | `no`  | HTTPS nodeport where nginx ingress controller will listen. Default 30443 |
| `k8s_server_pool_size`  | `no`  | Number of k8s servers deployed. Default 2  |
| `k8s_worker_pool_size`  | `no`  | Number of k8s workers deployed. Default 2  |
| `install_nginx_ingress`  | `no`  | Boolean value, install kubernetes nginx ingress controller. Default: false. |
| `install_longhorn`  | `no`  | Boolean value, install longhorn "Cloud native distributed block storage for Kubernetes". Default: false  |
| `longhorn_release`  | `no`  | Longhorn release. Default: v1.2.3  |
| `unique_tag_key`  | `no`  | Unique tag name used for tagging all the deployed resources. Default: k8s-provisioner |
| `unique_tag_value`  | `no`  | Unique value used with  unique_tag_key. Default: https://github.com/garutilorenzo/k8s-oci-cluster |
| `PATH_TO_PUBLIC_KEY`     | `no`       | Path to your public ssh key (Default: "~/.ssh/id_rsa.pub) |
| `PATH_TO_PRIVATE_KEY` | `no`        | Path to your private ssh key (Default: "~/.ssh/id_rsa) |


#### How to find the availability doamin name

To find the list of the availability domains run this command on che Cloud Shell:

```
oci iam availability-domain list
{
  "data": [
    {
      "compartment-id": "<compartment_ocid>",
      "id": "ocid1.availabilitydomain.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "name": "iAdc:EU-ZURICH-1-AD-1"
    }
  ]
}
```

#### How to list all the OS images

To filter the OS images by shape and OS run this command on che Cloud Shell:

```
oci compute image list --compartment-id <compartment_ocid> --operating-system "Canonical Ubuntu" --shape "VM.Standard.A1.Flex"
{
  "data": [
    {
      "agent-features": null,
      "base-image-id": null,
      "billable-size-in-gbs": 2,
      "compartment-id": null,
      "create-image-allowed": true,
      "defined-tags": {},
      "display-name": "Canonical-Ubuntu-20.04-aarch64-2022.01.18-0",
      "freeform-tags": {},
      "id": "ocid1.image.oc1.eu-zurich-1.aaaaaaaag2uyozo7266bmg26j5ixvi42jhaujso2pddpsigtib6vfnqy5f6q",
      "launch-mode": "NATIVE",
      "launch-options": {
        "boot-volume-type": "PARAVIRTUALIZED",
        "firmware": "UEFI_64",
        "is-consistent-volume-naming-enabled": true,
        "is-pv-encryption-in-transit-enabled": true,
        "network-type": "PARAVIRTUALIZED",
        "remote-data-volume-type": "PARAVIRTUALIZED"
      },
      "lifecycle-state": "AVAILABLE",
      "listing-type": null,
      "operating-system": "Canonical Ubuntu",
      "operating-system-version": "20.04",
      "size-in-mbs": 47694,
      "time-created": "2022-01-27T22:53:34.270000+00:00"
    },
```

**Note:** this setup was only tested with Ubuntu 20.04

## Notes about OCI always free resources

In order to get the maximum resources available within the oracle always free tier, the max amount of the k8s servers and k8s workers must be 2. So the max value for *k8s_server_pool_size* and *k8s_worker_pool_size* **is** 2.

In this setup we use two LB, one internal LB and one public LB (Layer 7). In order to use two LB using the always free resources, one lb must be a [network load balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/introducton.htm#Overview) an the other must be a [load balancer](https://docs.oracle.com/en-us/iaas/Content/Balance/Concepts/balanceoverview.htm). The public LB **must** use the *flexible* shape (*public_lb_shape* variable).

## Infrastructure overview

The final infrastructure will be made by:

* two instance pool:
  * one instance pool for the server nodes named "k8s-servers"
  * one instance pool for the worker nodes named "k8s-workers"
* one internal load balancer that will route traffic to k8s servers
* one external load balancer that will route traffic to k8s workers

The other resources created by terraform are:

* two instance configurations (one for the servers and one for the workers) used by the instance pools
* one vcn
* two public subnets
* two security list
* one dynamic group
* one identity policy

## Kubernetes setup

The installation of K8s id done by [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/). In this installation [Containerd](https://containerd.io/) is used as CRI and [flannel](https://github.com/flannel-io/flannel) is used as CNI.

You can optionally install [Nginx ingress controller](https://kubernetes.github.io/ingress-nginx/) and [Longhorn](#https://longhorn.io/).

To install Nginx ingress set the variable *install_nginx_ingress* to yes (default no). To install longhorn set the variable *install_longhorn* to yes (default no). **NOTE** if you don't install the nginx ingress, the public Load Balancer and the SSL certificate won't be deployed.

In this installation is used a OCI bucket to store the join certificate/token. At the first startup of the instance, if the cluster does not exist, the OCI bucket is used to get the join certificates/token.

## Deploy

We are now ready to deploy our infrastructure. First we ask terraform to plan the execution with:

```
terraform plan

...
...
      + id                             = (known after apply)
      + ip_addresses                   = (known after apply)
      + is_preserve_source_destination = false
      + is_private                     = true
      + lifecycle_details              = (known after apply)
      + nlb_ip_version                 = (known after apply)
      + state                          = (known after apply)
      + subnet_id                      = (known after apply)
      + system_tags                    = (known after apply)
      + time_created                   = (known after apply)
      + time_updated                   = (known after apply)

      + reserved_ips {
          + id = (known after apply)
        }
    }

Plan: 27 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + k8s_servers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + k8s_workers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + public_lb_ip    = (known after apply)

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

now we can deploy our resources with:

```
terraform apply

...
...
  + resource "oci_objectstorage_bucket" "cert_bucket" {
      + access_type                  = "NoPublicAccess"
      + approximate_count            = (known after apply)
      + approximate_size             = (known after apply)
      + auto_tiering                 = (known after apply)
      + bucket_id                    = (known after apply)
      + compartment_id               = "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      + created_by                   = (known after apply)
      + defined_tags                 = (known after apply)
      + etag                         = (known after apply)
      + freeform_tags                = {
          + "environment"     = "staging"
          + "k8s-provisioner" = "https://github.com/garutilorenzo/k8s-oci-cluster"
          + "provisioner"     = "terraform"
          + "scope"           = "k8s-cluster"
          + "uuid"            = "xxxx-xxxx-xxxx-xxxxxx"
        }
      + id                           = (known after apply)
      + is_read_only                 = (known after apply)
      + kms_key_id                   = (known after apply)
      + name                         = "my-very-secure-k8s-bucket"
      + namespace                    = "xxxxxxxxx"
      + object_events_enabled        = (known after apply)
      + object_lifecycle_policy_etag = (known after apply)
      + replication_enabled          = (known after apply)
      + storage_tier                 = (known after apply)
      + time_created                 = (known after apply)
      + versioning                   = (known after apply)
    }

Plan: 31 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + k8s_servers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + k8s_workers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + public_lb_ip    = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

...
...

module.k8s_cluster.oci_load_balancer_backend.k8s_http_backend[0]: Still creating... [40s elapsed]
module.k8s_cluster.oci_load_balancer_backend.k8s_https_backend[0]: Still creating... [40s elapsed]
module.k8s_cluster.oci_load_balancer_backend.k8s_http_backend[0]: Still creating... [50s elapsed]
module.k8s_cluster.oci_load_balancer_backend.k8s_https_backend[0]: Still creating... [50s elapsed]
module.k8s_cluster.oci_load_balancer_backend.k8s_http_backend[0]: Still creating... [1m0s elapsed]
module.k8s_cluster.oci_load_balancer_backend.k8s_https_backend[0]: Still creating... [1m0s elapsed]
module.k8s_cluster.oci_load_balancer_backend.k8s_http_backend[0]: Creation complete after 1m0s [id=loadBalancers/ocid1.loadbalancer.oc1.eu-zurich-1.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/backendSets/k8s_http_backend_set/backends/10.0.0.153:30080]
module.k8s_cluster.oci_load_balancer_backend.k8s_https_backend[0]: Creation complete after 1m10s [id=loadBalancers/ocid1.loadbalancer.oc1.eu-zurich-1.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/backendSets/k8s_https_backend_set/backends/10.0.0.153:30443]

Apply complete! Resources: 31 added, 0 changed, 0 destroyed.

Outputs:

k8s_servers_ips = [
  "152.x.x.x",
  "140.x.x.x",
]
k8s_workers_ips = [
  "152.x.x.x",
  "140.x.x.x",
]
public_lb_ip = tolist([
  "144.x.x.x",
])
```

Now on one master node you can check the status of the cluster with:

```
ssh 152.X.X.X -lubuntu

ubuntu@inst-ctrpq-k8s-servers:~$ sudo su -
root@inst-ctrpq-k8s-servers:~# kubectl get nodes
NAME                     STATUS   ROLES                  AGE     VERSION
inst-4iekh-k8s-workers   Ready    <none>                 3m37s   v1.23.5
inst-ctrpq-k8s-servers   Ready    control-plane,master   4m33s   v1.23.5
inst-gasrn-k8s-workers   Ready    <none>                 3m40s   v1.23.5
inst-ned7t-k8s-servers   Ready    control-plane,master   5m45s   v1.23.5
```

#### Public LB check

We can now test the public load balancer, nginx ingress controller and the security list ingress rules. On your local PC run:

```
curl -v http://PUBLIC_LB_IP
*   Trying PUBLIC_LB_IP:80...
* TCP_NODELAY set
* Connected to PUBLIC_LB_IP (PUBLIC_LB_IP) port 80 (#0)
> GET / HTTP/1.1
> Host: PUBLIC_LB_IP
> User-Agent: curl/7.68.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Date: Wed, 20 Apr 2022 09:07:41 GMT
< Content-Type: text/html
< Content-Length: 146
< Connection: keep-alive
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host PUBLIC_LB_IP left intact
```

*404* is a correct response since the cluster is empty. We can test also the https listener/backends:

```
curl -k -v https://PUBLIC_LB_IP
*   Trying PUBLIC_LB_IP:443...
* TCP_NODELAY set
* Connected to PUBLIC_LB_IP (PUBLIC_LB_IP) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: C=IT; ST=Italy; L=Brescia; O=GL Ltd; OU=IT; CN=testlb.domainexample.com; emailAddress=email@you.com
*  start date: Apr 11 08:20:12 2022 GMT
*  expire date: Apr 11 08:20:12 2023 GMT
*  issuer: C=IT; ST=Italy; L=Brescia; O=GL Ltd; OU=IT; CN=testlb.domainexample.com; emailAddress=email@you.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
> GET / HTTP/1.1
> Host: PUBLIC_LB_IP
> User-Agent: curl/7.68.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Date: Wed, 20 Apr 2022 09:13:17 GMT
< Content-Type: text/html
< Content-Length: 146
< Connection: keep-alive
< Strict-Transport-Security: max-age=15724800; includeSubDomains
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host PUBLIC_LB_IP left intact
```

#### Longhorn check

To check if longhorn was successfully installed run on one master nodes:

```
root@inst-ctrpq-k8s-servers:~# kubectl get ns
NAME              STATUS   AGE
default           Active   7m2s
ingress-nginx     Active   3m24s
kube-node-lease   Active   7m4s
kube-public       Active   7m4s
kube-system       Active   7m4s
longhorn-system   Active   3m22s <- longhorn namespace 

root@inst-ctrpq-k8s-servers:~# kubectl get pods -n longhorn-system
NAME                                        READY   STATUS    RESTARTS        AGE
csi-attacher-6454556647-2rjmz               1/1     Running   0               2m53s
csi-attacher-6454556647-6cmbp               1/1     Running   0               2m53s
csi-attacher-6454556647-dpt8x               1/1     Running   0               2m53s
csi-provisioner-869bdc4b79-25qgq            1/1     Running   0               2m52s
csi-provisioner-869bdc4b79-6cpws            1/1     Running   0               2m52s
csi-provisioner-869bdc4b79-8rbd2            1/1     Running   0               2m52s
csi-resizer-6d8cf5f99f-g7p89                1/1     Running   0               2m51s
csi-resizer-6d8cf5f99f-kjr7l                1/1     Running   0               2m51s
csi-resizer-6d8cf5f99f-wffrt                1/1     Running   0               2m51s
csi-snapshotter-588457fcdf-lt5g2            1/1     Running   0               2m47s
csi-snapshotter-588457fcdf-rwzkr            1/1     Running   0               2m47s
csi-snapshotter-588457fcdf-sqpnf            1/1     Running   0               2m49s
engine-image-ei-fa2dfbf0-4c92z              1/1     Running   0               3m11s
engine-image-ei-fa2dfbf0-5lg9g              1/1     Running   0               3m11s
engine-image-ei-fa2dfbf0-85qw7              1/1     Running   0               3m11s
engine-image-ei-fa2dfbf0-pvdb4              1/1     Running   0               3m11s
instance-manager-e-0875a5db                 1/1     Running   0               3m2s
instance-manager-e-2de68cb1                 1/1     Running   0               3m8s
instance-manager-e-dc60e8b8                 1/1     Running   0               2m53s
instance-manager-e-eafd289e                 1/1     Running   0               3m11s
instance-manager-r-1b69bd4c                 1/1     Running   0               3m2s
instance-manager-r-2b769288                 1/1     Running   0               3m7s
instance-manager-r-c540059f                 1/1     Running   0               2m53s
instance-manager-r-d17351ca                 1/1     Running   0               3m10s
longhorn-csi-plugin-hft24                   2/2     Running   0               2m45s
longhorn-csi-plugin-ljcfp                   2/2     Running   0               2m45s
longhorn-csi-plugin-s5ww2                   2/2     Running   0               2m45s
longhorn-csi-plugin-s77qm                   2/2     Running   0               2m46s
longhorn-driver-deployer-7dddcdd5bb-8pjjm   1/1     Running   0               3m41s
longhorn-manager-7rfwc                      1/1     Running   0               3m39s
longhorn-manager-gmn9n                      1/1     Running   1 (3m13s ago)   3m39s
longhorn-manager-k9kms                      1/1     Running   1 (3m13s ago)   3m42s
longhorn-manager-zt5dw                      1/1     Running   1 (3m13s ago)   3m42s
longhorn-ui-7648d6cd69-2llgx                1/1     Running   0               3m42s
```

## Deploy a sample stack

Finally to test all the components of the cluster we can deploy a sample stack. The stack is composed by the following components:

* MariaDB
* Nginx
* Wordpress

Each component is made by: one deployment and one service.
Wordpress and nginx share the same persistent volume (ReadWriteMany with longhorn storage class). The nginx configuration is stored in four ConfigMaps and  the nginx service is exposed by the nginx ingress controller.

Deploy the resources with:

```
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k8s-oci-cluster/master/deployments/mariadb/all-resources.yml
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k8s-oci-cluster/master/deployments/nginx/all-resources.yml
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k8s-oci-cluster/master/deployments/wordpress/all-resources.yml
```

and check the status:

```
kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
mariadb       1/1     1            1           92m
nginx         1/1     1            1           79m
wordpress     1/1     1            1           91m

kubectl get svc
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes        ClusterIP   10.43.0.1       <none>        443/TCP    5h8m
mariadb-svc       ClusterIP   10.43.184.188   <none>        3306/TCP   92m
nginx-svc         ClusterIP   10.43.9.202     <none>        80/TCP     80m
wordpress-svc     ClusterIP   10.43.242.26    <none>        9000/TCP   91m
```

Now you are ready to setup WP, open the LB public ip and follow the wizard. **NOTE** nginx and the Kubernetes Ingress rule are configured without virthual host/server name.

To clean the deployed resources:

```
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/mariadb/all-resources.yml
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/nginx/all-resources.yml
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/wordpress/all-resources.yml
```

## Clean up

```
terraform destroy
```