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

- [Kubernetes on OCI](#deploy-kubernetes-on-amazon-aws)
- [Table of Contents](#table-of-contents)
    - [Important notes](#important-notes)
    - [Requirements](#requirements)
    - [Supported OS](#supported-os)
    - [Terraform OCI user creation (Optional)](#terraform-oci-user-creation-optional)
      - [Example RSA key generation](#example-rsa-key-generation)
    - [Project setup](#project-setup)
    - [Oracle provider setup](#oracle-provider-setup)
    - [Pre flight checklist](#pre-flight-checklist)
      - [How to find the availability doamin name](#how-to-find-the-availability-doamin-name)
      - [How to list all the OS images](#how-to-list-all-the-os-images)
  - [Notes about OCI always free resources](#notes-about-oci-always-free-resources)
  - [Infrastructure overview](#infrastructure-overview)
  - [Kubernetes setup](#kubernetes-setup)
  - [Deploy](#deploy)
  - [Deploy a sample stack](#deploy-a-sample-stack)
  - [Clean up](#clean-up)

**Note** choose a region with enough ARM capacity

### Important notes

* This is repo shows only how to use terraform with the Oracle Cloud infrastructure and use only the **always free** resources. This examples are **not** for a production environment.
* At the end of your trial period (30 days). All the paid resources deployed will be stopped/terminated
* At the end of your trial period (30 days), if you have a running compute instance it will be stopped/hibernated

### Requirements

To use this repo you will need:

* an Oracle Cloud account. You can register [here](https://cloud.oracle.com)

Once you get the account, follow the *Before you begin* and *1. Prepare* step in [this](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm) document.

### Supported OS

This module was tested with:

* Ubuntu 22.04 (ubuntu remote user)
* Ubuntu 22.04 Minimal (ubuntu remote user)
* Oracle Linux 8 (opc remote user)

### Terraform OCI user creation (Optional)

Is always recommended to create a separate user and group in your preferred [domain](https://cloud.oracle.com/identity/domains) to use with Terraform.
This user must have less privileges possible (Zero trust policy). Below is an example policy that you can [create](https://cloud.oracle.com/identity/policies) allow `terraform-group` to manage all the resources needed by this module:

```
Allow group terraform-group to manage virtual-network-family in compartment id <compartment_ocid>
Allow group terraform-group to manage instance-family in compartment id <compartment_ocid>
Allow group terraform-group to manage compute-management-family in compartment id <compartment_ocid>
Allow group terraform-group to manage volume-family in compartment id <compartment_ocid>
Allow group terraform-group to manage load-balancers in compartment id <compartment_ocid>
Allow group terraform-group to manage network-load-balancers in compartment id <compartment_ocid>
Allow group terraform-group to manage dynamic-groups in compartment id <compartment_ocid>
Allow group terraform-group to manage policies in compartment id <compartment_ocid>
Allow group terraform-group to manage secret-family in compartment id <compartment_ocid>
Allow group terraform-group to manage key-family in compartment id <compartment_ocid>
Allow group terraform-group to manage secrets in compartment id <compartment_ocid>
Allow group terraform-group to manage vaults in compartment id <compartment_ocid>
```

See [how](#oracle-provider-setup) to find the compartment ocid. The user and the group have to be manually created before using this module.
To create the user go to **Identity & Security -> Users**, then create the group in **Identity & Security -> Groups** and associate the newly created user to the group. The last step is to create the policy in **Identity & Security -> Policies**.

#### Example RSA key generation

To use terraform with the Oracle Cloud infrastructure you need to generate an RSA key. Generate the rsa key with:

```
openssl genrsa -out ~/.oci/<your_name>-oracle-cloud.pem 4096
chmod 600 ~/.oci/<your_name>-oracle-cloud.pem
openssl rsa -pubout -in ~/.oci/<your_name>-oracle-cloud.pem -out ~/.oci/<your_name>-oracle-cloud_public.pem
```

replace `<your_name>` with your name or a string you prefer.

**NOTE**: `~/.oci/<your_name>-oracle-cloud_public.pem` will be used in  `terraform.tfvars` by the Oracle provider plugin, so please take note of this string.

### Project setup

Clone this repo and go in the `example/` directory:

```
git clone https://github.com/garutilorenzo/k8s-oci-cluster.git
cd k8s-oci-cluster/example/
```

Now you have to edit the `main.tf` file and you have to create the `terraform.tfvars` file. For more detail see [Oracle provider setup](#oracle-provider-setup) and [Pre flight checklist](#pre-flight-checklist).

Or if you prefer you can create an new empty directory in your workspace and create this three files:

* `terraform.tfvars` - More details in [Oracle provider setup](#oracle-provider-setup)
* `main.tf`
* `provider.tf`

The `main.tf` file will look like:

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
  public_key_path     = "<change_me>"
  region                 = var.region
  availability_domain    = "<change_me>"
  compartment_ocid       = var.compartment_ocid
  my_public_ip_cidr      = "<change_me>"
  environment            = "staging"
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

The `provider.tf` will look like:

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

In the `example/` directory of this repo you need to create a `terraform.tfvars` file, the file will look like:

```
fingerprint      = "<rsa_key_fingerprint>"
private_key_path = "~/.oci/<your_name>-oracle-cloud_public.pem"
user_ocid        = "<user_ocid>"
tenancy_ocid     = "<tenency_ocid>"
compartment_ocid = "<compartment_ocid>"
```

To find your `tenency_ocid` in the Ocacle Cloud console go to: **Governance and Administration > Tenency details**, then copy the OCID.

To find you `user_ocid` in the Ocacle Cloud console go to **User setting** (click on the icon in the top right corner, then click on User settings), click your username and then copy the OCID.

The `compartment_ocid` is the same as `tenency_ocid`.

The fingerprint is the fingerprint of your RSA key, you can find this vale under **User setting > API Keys**.

### Pre flight checklist

Once you have created the terraform.tfvars file edit the `main.tf` file (always in the `example/` directory) and set the following variables:

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
| `cluster_name`  | `no`  | Kubernetes cluster name. Default: kubernetes  |
| `k8s_version`  | `no`  | Kubernetes version to install  |
| `k8s_pod_subnet`  | `no`  | Kubernetes pod subnet managed by the CNI (Flannel). Default: 10.244.0.0/16 |
| `k8s_service_subnet`  | `no`  | Kubernetes pod service managed by the CNI (Flannel). Default: 10.96.0.0/12 |
| `k8s_dns_domain`  | `no`  | Internal kubernetes DNS domain. Default: cluster.local |
| `kube_api_port`  | `no`  | Kube api default port Default: 6443  |
| `public_lb_shape`  | `no`  | LB shape for the public LB. Default: flexible. **NOTE** is mandatory to use this kind of shape to provision two always free LB (public and private)  |
| `http_lb_port`  | `no`  | http port used by the public LB. Default: 80  |
| `https_lb_port`  | `no`  | http port used by the public LB. Default: 443  |
| `ingress_controller_http_nodeport`  | `no`  | HTTP nodeport where nginx ingress controller will listen. Default: 30080 |
| `ingress_controller_https_nodeport`  | `no`  | HTTPS nodeport where nginx ingress controller will listen. Default 30443 |
| `k8s_server_pool_size`  | `no`  | Number of k8s servers deployed. Default 1  |
| `k8s_worker_pool_size`  | `no`  | Number of k8s workers deployed. Default 2  |
| `k8s_extra_worker_node`  | `no`  | Boolean value, default true. Deploy the third worker nodes. The node will be deployed outside the worker instance pools. Using OCI always free account you can't create instance pools with more than two servers. This workaround solve this problem.  |
| `install_nginx_ingress`  | `no`  | Boolean value, install kubernetes nginx ingress controller. Default: false. |
| `nginx_ingress_release`  | `no`  | Nginx ingress release to install. Default: v1.5.1|
| `install_longhorn`  | `no`  | Boolean value, install longhorn "Cloud native distributed block storage for Kubernetes". Default: false  |
| `longhorn_release`  | `no`  | Longhorn release. Default: v1.4.0  |
| `install_certmanager`  | `no`  | Boolean value, install [cert manager](https://cert-manager.io/) "Cloud native certificate management". Default: true  |
| `certmanager_release`  | `no`  | Cert manager release. Default: v1.11.0  |
| `certmanager_email_address`  | `no`  | Email address used for signing https certificates. Defaul: changeme@example.com  |
| `expose_kubeapi`  | `no`  | Boolean value, default false. Expose or not the kubeapi server to the internet. Access is granted only from my_public_ip_cidr for security reasons.  |
| `hash_secret_name`  | `no`  | Secret name where kubernetes hash is stored  |
| `token_secret_name`  | `no`  | Secret name where kubernetes token is stored  |
| `cert_secret_name`  | `no`  | Secret name where kubernetes cert is stored  |
| `kubeconfig_secret_name  | `no`  | Secret name where kubernetes kubeconfig is stored  |
| `public_key_path`     | `no`       | Path to your public ssh key (Default: "~/.ssh/id_rsa.pub) |

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

To filter the OS images by shape and OS run this command on che Cloud Shell. You can filter by OS: Canonical Ubuntu or Oracle Linux:

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

**Note:** this setup was tested with Ubuntu 22.04 and Oracle Linux 8

## Notes about OCI always free resources

In order to get the maximum resources available within the oracle always free tier and to get the k8s cluster in HA `k8s_server_pool_size` is set to 1 (single master node) and `k8s_worker_pool_size` is set to 2.
With the latest release was introduced the new variable `k8s_extra_worker_node`. With this variable set to `true` (Default) a third worker node will be added.
In previous releases the master nodws where two, but this didn't guarantee the HA of the cluster.

In this setup we use two LB, one internal LB (Layer 7) and one public LB (Layer 4). In order to use two LB using the always free resources, one lb must be a [network load balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/introducton.htm#Overview) an the other must be a [load balancer](https://docs.oracle.com/en-us/iaas/Content/Balance/Concepts/balanceoverview.htm). The public LB **must** use the `flexible` shape (`public_lb_shape` variable).

## Infrastructure overview

The final infrastructure will be made by:

* two instance pool:
  * one instance pool for the server nodes named `k8s-servers`
  * one instance pool for the worker nodes named `k8s-workers`
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

This modules uses OCI vault secrets to store join certificates.

## Cluster resource deployed

You can optionally install [longhorn](https://longhorn.io/). Longhorn is a *Cloud native distributed block storage for Kubernetes*. To enable the longhorn deployment set `install_longhorn` variable to `true`.

**NOTE** to use longhorn set the `k8s_version` < `v1.25.x` [Ref.](https://github.com/longhorn/longhorn/issues/4003)

### Nginx ingress controller

You can optionally install [Nginx ingress controller](https://kubernetes.github.io/ingress-nginx/) To enable the longhorn deployment set `install_nginx_ingress` variable to `true`.

The installation is the [bare metal](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters) installation, the ingress controller then is exposed via a NodePort Service.

```yaml
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
```

To get the real ip address of the clients using a public L4 load balancer we need to use the proxy protocol feature of nginx ingress controller:

```yaml
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
```

**NOTE** to use nginx ingress controller with the proxy protocol enabled, an external nginx instance is used as proxy (since OCI LB doesn't support proxy protocol at the moment). Nginx will be installed on each worker node and the configuation of nginx will:

* listen in proxy protocol mode
* forward the traffic from port `80` to `extlb_listener_http_port` (default to `30080`) on any server of the cluster
* forward the traffic from port `443` to `extlb_listener_https_port` (default to `30443`) on any server of the cluster

This is the final result:

Client -> Public L4 LB -> nginx proxy (with proxy protocol enabled) -> nginx ingress (with proxy protocol enabled) -> k3s service -> pod(s)

### Cert-manager

[cert-manager](https://cert-manager.io/docs/) is used to issue certificates from a variety of supported source. To use cert-manager take a look at [nginx-ingress-cert-manager.yml](https://github.com/garutilorenzo/k3s-oci-cluster/blob/master/deployments/nginx/nginx-ingress-cert-manager.yml) and [nginx-configmap-cert-manager.yml](https://github.com/garutilorenzo/k3s-oci-cluster/blob/master/deployments/nginx/nginx-configmap-cert-manager.yml) example. To use cert-manager and get the certificate you **need** set on your DNS configuration the public ip address of the load balancer.

## Deploy

We are now ready to deploy our infrastructure. First we ask terraform to plan the execution with:

```
terraform plan

...
...
      # module.k8s_cluster.oci_vault_secret.kubeconfig_secret_name will be created
      + resource "oci_vault_secret" "kubeconfig_secret_name" {
      + compartment_id                 = "ocid1.tenancy.oc1..aaaaaaaacuobj3enmdjf3j7heb3vwr2iqtcb266xlkczo3ifxubiuep6fvpq"
      + current_version_number         = (known after apply)
      + defined_tags                   = (known after apply)
      + description                    = "Kubeconfig hash"
      + freeform_tags                  = {
          + "application"      = "k8s"
          + "environment"      = "staging"
          + "k3s_cluster_name" = "kubernetes"
          + "provisioner"      = "terraform"
          + "terraform_module" = "https://github.com/garutilorenzo/k8s-oci-cluster"
        }
      + id                             = (known after apply)
      + key_id                         = "ocid1.key.oc1.eu-zurich-1.c5r5vcceaaanu.ab5heljr74iutguojeaogcb5or5kqb3q6uxs2njuua5fkr6nlhlh67uukrbq"
      + lifecycle_details              = (known after apply)
      + metadata                       = (known after apply)
      + secret_name                    = "k8s-hash-staging"
      + state                          = (known after apply)
      + time_created                   = (known after apply)
      + time_of_current_version_expiry = (known after apply)
      + time_of_deletion               = (known after apply)
      + vault_id                       = "ocid1.vault.oc1.eu-zurich-1.c5r5vcceaaanu.ab5heljr6pnyytb2bn7fdfacyo2eses7mcgbnv7wqhvwcckjjfvekn2tmefq"

      + secret_content {
          + content      = "ZW1wdHkga3ViZWNvbmZpZyBzZWNyZXQ="
          + content_type = "BASE64"
          + name         = (known after apply)
          + stage        = (known after apply)
        }

      + secret_rules {
          + is_enforced_on_deleted_secret_versions        = (known after apply)
          + is_secret_content_retrieval_blocked_on_expiry = (known after apply)
          + rule_type                                     = (known after apply)
          + secret_version_expiry_interval                = (known after apply)
          + time_of_absolute_expiry                       = (known after apply)
        }
    }

  # module.k8s_cluster.oci_vault_secret.token_secret will be updated in-place
  ~ resource "oci_vault_secret" "token_secret" {
        id                     = "ocid1.vaultsecret.oc1.eu-zurich-1.amaaaaaa5kjm7pyaob2ryqa5q4awwgkugs2it37pjmnlj7ldd6kr2ssqubpa"
        # (11 unchanged attributes hidden)

      + secret_content {
          + content      = "ZW1wdHkgdG9rZW4gc2VjcmV0"
          + content_type = "BASE64"
        }

        # (1 unchanged block hidden)
    }

Plan: 41 to add, 3 to change, 0 to destroy.

Changes to Outputs:
  + k8s_servers_ips = [
      + (known after apply),
    ]
  + k8s_workers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + public_lb_ip    = (known after apply)

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

now we can deploy our resources with:

```
terraform apply

...
...

Plan: 41 to add, 3 to change, 0 to destroy.

Changes to Outputs:
  + k8s_servers_ips = [
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

module.k8s_cluster.oci_network_load_balancer_backend.k8s_http_backend_extra_node[0]: Still creating... [1m40s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_https_backend_extra_node[0]: Still creating... [1m40s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_http_backend_extra_node[0]: Still creating... [1m50s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_https_backend_extra_node[0]: Still creating... [1m50s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_https_backend_extra_node[0]: Still creating... [2m0s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_http_backend_extra_node[0]: Still creating... [2m0s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_https_backend_extra_node[0]: Creation complete after 2m8s [id=networkLoadBalancers/ocid1.networkloadbalancer.oc1.eu-zurich-1.xxxxxx/backendSets/k8s_https_backend/backends/ocid1.instance.oc1.eu-zurich-1.xxxxxx:443]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_http_backend_extra_node[0]: Still creating... [2m10s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_http_backend_extra_node[0]: Still creating... [2m20s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_http_backend_extra_node[0]: Still creating... [2m30s elapsed]
module.k8s_cluster.oci_network_load_balancer_backend.k8s_http_backend_extra_node[0]: Creation complete after 2m34s [id=networkLoadBalancers/ocid1.networkloadbalancer.oc1.eu-zurich-1.xxxxxx/backendSets/k8s_http_backend/backends/ocid1.instance.oc1.eu-zurich-1.xxxxxx:80]

Apply complete! Resources: 41 added, 3 changed, 0 destroyed.

Outputs:

k8s_servers_ips = [
  "140.x.x.x",
]
k8s_workers_ips = [
  "140.x.x.x",
  "152.x.x.x",
]
public_lb_ip = tolist([
  {
    "ip_address" = "152.x.x.x"
    "ip_version" = "IPV4"
    "is_public" = true
    "reserved_ip" = tolist([])
  },
  {
    "ip_address" = "10.x.x.x"
    "ip_version" = "IPV4"
    "is_public" = false
    "reserved_ip" = tolist([])
  },
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
< Date: Sat, 04 Feb 2023 11:06:30 GMT
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
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  start date: Feb  3 09:26:14 2023 GMT
*  expire date: Feb  3 09:26:14 2024 GMT
*  issuer: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x5566c6bfa2f0)
> GET / HTTP/2
> Host: PUBLIC_LB_IP
> user-agent: curl/7.68.0
> accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 404 
< date: Sat, 04 Feb 2023 11:07:06 GMT
< content-type: text/html
< content-length: 146
< strict-transport-security: max-age=15724800; includeSubDomains
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