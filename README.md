# Raspberry Pi Cluster Setup

<!-- vim-markdown-toc GFM -->

* [Prepare SD Card](#prepare-sd-card)
* [Rack N Stack](#rack-n-stack)
* [Install K3S](#install-k3s)
    * [Pre-requisites](#pre-requisites)
    * [Install](#install)
    * [Test](#test)
* [Infra as Code (WIP)](#infra-as-code-wip)

<!-- vim-markdown-toc -->

## Prepare SD Card
We're using [Ubuntu Server](https://ubuntu.com/download/raspberry-pi) image for our Raspberry PIs in the cluster. We use the included `prepare_sdcard.sh` script to:
- Take a number $num as argument to set `pi-${num}` as hostname of a Pi
- Ensure a few specific environment variables are set
- Display environment variables and summary of operations
- Unmount SD card partition(s)
- Write Image to SD card
- Edit partition table to expand filesystem to fill available space
- Repair and resize filesystem to commit above changes
- Eject and remount SD card to configure it for hostname
- Use `user-data` file to configure SD card using [Cloud Init](https://cloudinit.readthedocs.io)

```
./prepare_sdcard.sh
Usage: ./prepare_sdcard.sh <start_range> <end_range>

# To prepare 15 SD cards one after another
./prepare_sdcard.sh 01 15
...
```

## Rack N Stack
Rack up all the PIs, connect them all to the network, and they should be available.
```
xpanes -C 5 --ssh ansible@pi-{01..15}

```
![tmux-xpanes](pi-cluster.png)

## Install K3S
### Pre-requisites
- Run `sudo apt install linux-modules-extra-raspi` as per Rancher's docs to enable VxLan on Ubuntu Server for Raspberry PI
- Run `sudo ufw allow proto tcp from 192.168.1.0/24 to any port 6443` to allow incoming traffic from `192.168.1.*` into port 6443

### Install
Simplest way to install K3S has been to follow [K3S-Ansible](https://github.com/k3s-io/k3s-ansible). The version used at the time of setting up this cluster is saved here as a submodule.

### Test
Install `kubectl` on your local machine with `Homebrew` or your favorite package manager.

The last step in the `k3s-ansible` README is to copy `~/.kube/config` from the master node to local machine.

Now, on your local machine, you should be able to do something like this:
```
❯ kubectl get nodes -o wide
NAME    STATUS   ROLES                  AGE   VERSION        INTERNAL-IP     EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION      CONTAINER-RUNTIME
pi-15   Ready    <none>                 41m   v1.22.3+k3s1   192.168.1.136   <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-10   Ready    <none>                 42m   v1.22.3+k3s1   192.168.1.197   <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-08   Ready    <none>                 42m   v1.22.3+k3s1   192.168.1.161   <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-03   Ready    <none>                 42m   v1.22.3+k3s1   192.168.1.57    <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-04   Ready    <none>                 42m   v1.22.3+k3s1   192.168.1.106   <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-01   Ready    control-plane,master   88m   v1.22.3+k3s1   192.168.1.70    <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-09   Ready    <none>                 42m   v1.22.3+k3s1   192.168.1.133   <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-13   Ready    <none>                 41m   v1.22.3+k3s1   192.168.1.199   <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-12   Ready    <none>                 41m   v1.22.3+k3s1   192.168.1.12    <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-05   Ready    <none>                 42m   v1.22.3+k3s1   192.168.1.151   <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-02   Ready    <none>                 42m   v1.22.3+k3s1   192.168.1.154   <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-07   Ready    <none>                 42m   v1.22.3+k3s1   192.168.1.34    <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
pi-14   Ready    <none>                 41m   v1.22.3+k3s1   192.168.1.17    <none>        Ubuntu 22.04 LTS   5.15.0-1013-raspi   containerd://1.5.7-k3s2
```

## Infra as Code (WIP)
[Funky Penguin's Geek Cookbook](https://geek-cookbook.funkypenguin.co.nz/) is a great resource to manage our pi-cluster like a farm and our services like cattle.
