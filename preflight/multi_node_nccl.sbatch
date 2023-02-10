#!/bin/bash
#SBATCH -n 192
#SBATCH -N 2
#SBATCH --gres=gpu:8

# we could also replace --gres=gpu:8 with --excluse to make it independent of number of GPUs on the node

NCCL_TEST_PATH=/tmp/nccl-tests/build
MPI_PATH=/opt/amazon/openmpi

# has to be exported if you're not running it from GPU node
# export LD_LIBRARY_PATH=:/opt/aws-ofi-nccl/lib:/opt/amazon/openmpi/lib64:/opt/amazon/efa/lib64:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/gdrcopy/lib:/opt/nccl/build/lib

export NCCL_PROTO=simple
export NCCL_DEBUG=INFO

export FI_EFA_USE_DEVICE_RDMA=1 # use for p4dn
export FI_EFA_FORK_SAFE=1
export FI_LOG_LEVEL=1
export FI_PROVIDER=efa
export FI_EFA_ENABLE_SHM_TRANSFER=0


$MPI_PATH/bin/mpirun --map-by ppr:8:node --rank-by slot \
    --mca pml ^cm  --mca btl tcp,self \
    --mca btl_tcp_if_exclude lo,docker0 --bind-to none \
    $NCCL_TEST_PATH/scatter_perf -b 8 -e 128 -f 2 -g 1 -c 1 -n 100
