# Build ParallelCluster AMI with EFA and GPU stacks <!-- omit in toc -->

## 1. Usage

Pre-requisites: `packer`, `ansible`, `make`, and an AWS account. The AWS account needs to have sufficient
limit to the instance type indicated by variable `instance_type` in file `packer-ami.pkr.hcl`.

Run `make ami_gpu` or `make ami_cpu` to build AMI for GPU with EFA and CPU supporting [pyxies](https://github.com/NVIDIA/pyxis) (see [here](https://github.com/NVIDIA/enroot/blob/9c6e979059699e93cfc1cce0967b78e54ad0e263/doc/cmd/import.md) to configure [AWS ECR](https://aws.amazon.com/ecr/) authentication out of the box ), while `make docker` builds container to use with GPUs and EFA. Run `make deploy` to deploy test cluster in `./test/cluster.yaml` assuming you have credentials in config file with default profile (`${HOME}/.aws`) and different parameters (AMI, subnets, ssh keys) are updated.

### 1.1. Notes

* Review `packer-ami.pkr.hcl` for all available variables.

  In particular, the EBS configuration affects both the AMI build time *AND* the EBS cost when you launch EC2 instances from the resulted AMI.

  * The EC2 instances must have at least the same `volume_size` in the `.hcl` file. The `.hcl` defaults to 100GB, which you may reduce because the actual space used is 17GB for CPU AMI, and 25GB for GPU AMI.

  * The EC2 instances will default to the `throughput` and `iops` in the `.hcl` file, but they can be changed before or after EC2 launch. Do note that lower values increases the AMI build time.

* We are using shared filesystem (`/fsx`) for container cache, set this accordingly to your cluster in `roles/nvidia_enroot_pyxis/templates/enroot.conf` variable `ENROOT_CACHE_PATH`.
* Review variables (dependency versions) in `./roles/*/defaults/main.yml` according to [Ansible directory structure](https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html).
* Optionally, to upgrade the PCluster version where the resulted AMI must be used, open `packer-ami.pkr.hcl` and edit variable `parallel_cluster_version`.

## 2. Preflight

Code is in `./preflight` directory. It consists of sanity checks for:

* Nvidia GPUs
* EFA and Nvidia NCCL
* PyTorch

### 2.1. Notes

* `torch.cuda.nccl.version()` in `preflight/preflight.sh` will return built in version, while searching for `NCCL version` if `NCCL_DEBUG=info` is exported will get preloaded version.

## 3. using Deep Learning AMI

[DLAMI](https://docs.aws.amazon.com/dlami/latest/devguide/what-is-dlami.html) contains common DL dependencies, it can be used with parallel cluster.
We can use following configuration:

```yaml
Build:
  InstanceType: p2.xlarge
  ParentImage: ami-123
```

where `ami-123` is ID of DLAMI of your choice. Run [pcluster build-image](https://docs.aws.amazon.com/parallelcluster/latest/ug/pcluster-v3.html) to add all pcluster dependencies.

## 4. Appendix: Initiate build AMI from MBP

Install pre-requisites:

```bash
brew install packer
brew install ansible
```

Review installed versions:

```console
% uname -a
Darwin xxxx 22.3.0 Darwin Kernel Version 22.3.0: Mon Jan 30 20:38:37 PST 2023; root:xnu-8792.81.3~2/RELEASE_ARM64_T6000 arm64

% packer --version
1.8.6

% brew info ansible
...
==> ansible: stable 7.3.0 (bottled), HEAD
Automate deployment, configuration, and upgrading
https://www.ansible.com/
/opt/homebrew/Cellar/ansible/7.3.0 (29,825 files, 385.6MB) *
...

% ansible --version
ansible [core 2.14.3]
  config file = None
  configured module search path = ['/Users/xxxx/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /opt/homebrew/Cellar/ansible/7.3.0/libexec/lib/python3.11/site-packages/ansible
  ansible collection location = /Users/xxxx/.ansible/collections:/usr/share/ansible/collections
  executable location = /opt/homebrew/bin/ansible
  python version = 3.11.2 (main, Feb 16 2023, 02:55:59) [Clang 14.0.0 (clang-1400.0.29.202)] (/opt/homebrew/Cellar/ansible/7.3.0/libexec/bin/python3.11)
  jinja version = 3.1.2
  libyaml = True
```

Now, your MBP is ready to kickstart an AMI build process.

```console
$ /usr/bin/time make ami_cpu
...
Build 'amazon-ebs.aws-pcluster-ami' finished after 10 minutes 17 seconds.

==> Wait completed after 10 minutes 17 seconds

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.aws-pcluster-ami: AMIs were created:
us-east-1: ami-04739f364ba5789ba

      619.46 real        18.52 user        10.58 sys
# Above is with default ebs in .hcl: (100GB, 10000 IOPS, 1000 MB/s)
#
# With EBS=(35GB, 1000 IOPS, 125 MB/s) => 15 minutes 39 seconds.
```

```console
$ /usr/bin/time make ami_gpu
...
Build 'amazon-ebs.aws-pcluster-ami' finished after 30 minutes 27 seconds.

==> Wait completed after 30 minutes 27 seconds

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.aws-pcluster-ami: AMIs were created:
us-east-1: ami-007662d3d06398c32

     1829.13 real        79.76 user        47.00 sys
# Above is with default EBS in .hcl: (100GB, 10000 IOPS, 1000 MB/s)
#
# With EBS=(35GB, 1000 IOPS, 125 MB/s) => 58 minutes 1 second.
```
