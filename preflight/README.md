# Using preflight
Run bash script `preflight.sh` inside this (`./preflight`) directory (it depends on other scripts in the folder) with your python interpretes being first positional argument (it uses `python3` as default). Other environmental variables where any assigned value will enable them :
* `FABRICMANAGER_DISABLE` -> silence fabricmanager check
* `PYTORCH_INSTALL_DISABLE` -> prevent installing pytorch for distributed training tests
* `PYTORCH_DISABLE` -> prevent single node PyTorch tests
* `MULTINODE_DISABLE` -> prevent multi node NCCL and PyTorch tests

# Passive healthchecks
Both [cloudwatch GPU monitoring](https://aws.amazon.com/blogs/compute/capturing-gpu-telemetry-on-the-amazon-ec2-accelerated-computing-instances/) and [Prometheus based DCGM exporter](https://github.com/NVIDIA/dcgm-exporter) container [X ID error metrics](https://docs.nvidia.com/deploy/xid-errors/index.html) to detect any underlying issues with GPU. Users can further inspect `dmesg` for more information.

# Preflight future roadmap
* persist results in JSON or other structure file format

