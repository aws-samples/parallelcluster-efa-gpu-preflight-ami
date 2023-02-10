#!/bin/bash
set -euxo pipefail

FIRST=$(sbatch --parsable --wrap "grep PRETTY /etc/os-release")
SECOND=$(sbatch --parsable --container-image=centos --wrap "grep PRETTY /etc/os-release")
THIRD=$(sbatch --parsable --container-image=centos --container-mounts=/etc/os-release:/host/os-release --wrap "grep PRETTY /host/os-release")

sleep 10

grep --quiet 'PRETTY_NAME="Amazon Linux 2"' slurm-${FIRST}.out || echo "first failed"
grep --quiet 'PRETTY_NAME="CentOS Linux 8"' slurm-${SECOND}.out || echo "second failed"
grep --quiet 'PRETTY_NAME="Amazon Linux 2"' slurm-${THIRD}.out || echo "third failed"