# Kubernetes via Ansible

## 🔥 (Possible) DEPRECATION NOTICE 🔥
> So, I've not updated this in a while as I've discovered the joys of Terraform and the glory of programatically creating clusters using Goland/ClusterAPI and other methods. Now, I'm not completely abandoning this but for now there is no garuanteed updates (as you can see it's not been updated in 3+ years). One day I may get around to updating all of this - if I don't I'll archive it in 6-12 months - we'll see. I'm making it public and leaving it here in case anyone wants to play/use/update it/learn form the mistakes it makes. It was something I created back in the day when I was learning Kubernetes and attempting to automate it.

These playbooks are designed to help people who want a Kubernetes cluster and don't want to rely on the cloud providers to get one.
The process is still in development and ETCD will soon be separated out from the Master Nodes to allow for better reliability.
The idea behind it is to give you a close-to-production including GitOps tools (flux), A Service Mesh (Istio), Monitoring (via Prometheus Operator), Helm and more.  

All you need to get going is 1 CentOS 8 machine capable of running VMs OR a collection of bare metal devices running CentOS 7.

If you're going for the VM route, which is the most mature, then you don't really need to do much other than provide a server to use as the VM host.
The playbooks will setup LibVirtD on the `builder` nodes and deploy the cluster. However for now it's designed to work with one builder, not multiple.
I intend to improve on this soon with a wrapper around virsh to provide a rest API (or find one if it exists) but it depends on time available.

## Features
* Cluster creation is managed using kubeadm.
* HA Control plane available with HAProxy provided as the LB.
* LB Provided for workers - I'm looking into creating a "Service Controller" based on the "Cloud Controller Manager" so that LoadBalancer service types can be created.
* Enabled auditing by default.
* [Flux](https://github.com/fluxcd/flux) - For GitOPs
* StorageOS is the default storage driver. This will put data in /var/lib/storageos/data on each worker node.
  Storage pools are created on the builder, attach and mount a disk to /var/lib/libvirt/images/storageos to expand on this storage.
* Helm v2 with SSL and RBAC, I'd love to go for v3 but until more charts or moved to v3 and things like Istio and Gitlab K8S integration move to the new version, we're stuck.
* Istio (Considering a switch to linkerd)

## Version
Alpha v0.1

## Notes/Known Issues
* If it breaks your cluster, I'm not responsible - this is a project meant for my cluster and it should work on **most** 
clusters but you know, who knows if dragons are real?
* If using bare metal (best for production):
    * Make sure you mark the nodes as remote in `host_vars/{HOST}/main.yml`.
    * StorageOS is brand new in this project and going through testing but should work fine.
    * You'll be responsible for Installing the OS, I'm not working with any TFTP/iPXe setups yet.
* If using LibVirt/KVM:
    * The playbooks pretty much do everything.
    * You may hit a few initial errors because a python module that I can't 
    install because you'd need THAT python module for me to do it (got that?), will have to be done by you.
    * You'll need to install Ansible first. I used `pip install ansible` on my local machine for all of this.
* If you want to use the Kemp Free LB, this will work but the licencing is a bit squiffy so you'll have to sort that yourself.
  * I can't pull the image without registration unless I provide some source for it so you'll need to do this, convert it to qcow2 and move it into the LibVirtD templates dir.
  * Do a find through the code to uncomment the relevant parts, I'll set this in a VAR this later.  
* There seems to be an issue with HAProxy managing persistent connections on the Control Plane at the moment.
  Things like  `kubectl get po -w` will drop and helm may fail. I'm looking into layer 7 over layer 4 balancing to see if I can negate this.

## How-To
* Set up Ansible on your machine
* Pull this code and:
  * Modify or comment out `hosts.yml` as required.
  * Configure your hosts within `host_vars/HOST_NAME/main.yml`. Check out `host_vars/all/main.yml.example` for an example.
  * Make sure you configure your variables in `group_vars/all/main.yml`. Check out `group_vars/all/main.yml.example` for an example.
* Turn on your Builder machine(s). I haven't gone so far as to build roles for magic packets etc... yet ;-)
* Go!

```bash
# --extra-vars available
# build_instances: true|false

## This command uses the root user to initialise the ansible_user on the buidler node.
## All VMs will be auto populated with this user. 
$ ansible-playbook adhoc/initialise_ansible_user.yml -k -c paramiko --become --ask-become-pass --ask-pass -c paramiko

## This builds the entire K8S cluster from scratch
$ ansible-playbook site.yml --extra-vars="build_instances=true"
```

There are some ad-hoc playbooks too alongside the `adhoc/initialise_ansible_user.yml`.
To generate a new token nodes will use for joining an existing cluster - `adhoc/generate_new_token.yml`


## More Details
The playbooks can be run per host or as phases. The phases are the default.
### 101 - Configure Ansible 
This section will install all the required yum/apt packages and python packages that will be required for this project to work. 
### 102 - Configure Builder 
This will configure the node you define as the builder node in the ```hosts.yml``` file. LibVirtd/QEMU etc is configured along with bridge networking.
### 103 - Deploy Instances
Deploys the instances used in the cluster via libvirt.
### 201 - Prepare Nodes
Install required packages on all nodes, configure firewall, hosts file and more common tasks.
### 202 - Configure loadbalancer
Configures the HAProxy load balancers. 
### 204 - Configure Storage -- Only used by NFS -- being deprecated from this project.
Configures NFS storage. 
### 301 - Initialise 1st Controller
Builds the first controller node for the cluster.
### 302 - Add Additional Controller Nodes 
Adds additional controller nodes for the control plane.
### 303 - Add Workers Nodes 
Add any worker nodes.
### 304 - Setup StorageOS 
Configure StorageOS on the cluster.
### 999 - Post Install Tasks 
Installs Helm, Istio, Kube-Prometheus (Prometheus Operator) and Flux.
