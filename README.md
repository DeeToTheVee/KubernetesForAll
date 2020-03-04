# Kubernetes via Ansible

These playbooks are designed to help people who want a Kubernetes cluster and don't want to rely on the cloud providers to get one.
The process is still in development and ETCD will soon be separated out from the Master Nodes to allow for better reliability.

All you need to get going is 1 CentOS 8 machine capable of running VMs OR a collection of bare metal devices running CentOS 7.

If you're going for the VM route, which is the most mature, then you don't really need to do much other than provide a server to user as the VM host.
The playbooks will setup LibVirtD on the `builder` nodes and deploy the cluster. However, It's designed to work with on builder, not multiple.
I intend to improve on this soon with a new Golang Wrapper around virsh to provide a rest API (or find one if it exists) but it depends on time available.

## Version
Such an early alpha there needs to be a new word.

## Plans
* I'm in the process of converting the storage nodes from NFS over to StorageOS.
* Separate ETCD nodes. 
* Enable Helm 3 Or Operators - probably Operators.
* Integrate Istio, or more likely, LinkerD (because Istio doesn't support Helm 3).

## Notes
* If it breaks your cluster, I'm not responsible - this is a project meant for my cluster and it should work on **most** 
clusters but you know, who knows if dragons are real?
* If using bare metal (best for production):
    * Make sure you mark the nodes as such in `group_vars/all/main.yml`.
    * StorageOS Setups **may** not work, but I'm working on it - It's still WIP on the VMs too.
    * You'll be responsible for Installing the OS, I'm not working with any TFTP/iPXe setups yet.
* If using LibVirt/KVM (best for testing on single physical nodes unless you have ridiculous resources):
    * The playbooks pretty much do everything.
    * You may hit a few initial errors because a python module that I can't 
    install because you'd need THAT python module for me to do it (got that?), will have to be done by you.
    * You'll need to install Ansible first. I used `pip install ansible` on my local machine for all of this.
* If you want to use the Kemp Free LB, this will work but the licencing is a bit squiffy so you'll have to sort that yourself.
  * I can't pull the image without registration unless I provide some source for it so you'll need to do this, convert it to qcow2 and move it into the LibVirtD templates dir.
  * Do a find through the code to uncomment the relevant parts, I'll set this in a VAR this later. 
  * With this in mind, I've been putting some work into **HaProxy** as an alternative but it's still a **work in progress**.
* I do have the playbooks ready for installing helm and istio, they are just currently disabled until further testing is done or I decide to get rid in favour of LinkrD and Operators. 

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
