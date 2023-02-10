#!/bin/bash
set -euxo pipefail


###########
###########
# GPU check
echo "Starting GPU tests"

N_GPUS=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | wc -l)
if [ ${N_GPUS} -eq 0 ]; then 
        echo "GPUs not present or no supported! nvidia-smi command failed.";
        exit 1
fi
echo "Number of GPUs: ${N_GPUS}"
nvidia-smi
nvcc -V
sudo updatedb
echo "System NCCL version: $(locate nccl | grep 'libnccl.so' | tail -n1 | sed -r 's/^.*\.so\.//')"
if [[ $(sudo systemctl is-active -q nvidia-fabricmanager.service) -ne 0 ]]; then
    if [[ ! -v FABRICMANAGER_DISABLE ]]; then
        echo "fabricmanager is not active"
        exit 1
    fi
fi
/tmp/nccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g ${N_GPUS}
echo "system GPU dependency check passed"

GDRCOPY_SANITY_LOG=gdrcopy.log
sanity > ${GDRCOPY_SANITY_LOG}
if [[ $(grep -q '100%: Checks: 27, Failures: 0, Errors: 0' ${GDRCOPY_SANITY_LOG}) -ne 0 ]]; then 
    echo "GDRCopy test failed!"
    exit 1
else
    echo "GDRCopy test passed"
fi
rm ${GDRCOPY_SANITY_LOG}

git clone https://github.com/wilicc/gpu-burn
cd gpu-burn
git checkout bcbfbce4677b854d8cb56a27286902e66118cb35
docker build -t gpu_burn .
cd ..
GPU_BURN_LOG=gpu_burn.log
docker run --rm --gpus all gpu_burn > ${GPU_BURN_LOG}
for gpu_id in $(seq 0 $(expr ${N_GPUS} - 1)); do
    if [[ $(grep -q "GPU ${gpu_id}" ${GPU_BURN_LOG}) -ne 0 ]]; then 
        echo "GPU stress test failed for GPU ${gpu_id}"
        exit 1
    fi
done
rm -rf gpu-burn
docker rmi gpu_burn


###########
###########
# EFA check
echo "Starting EFA tests"

if [ $(fi_info -p efa -t FI_EP_RDM | grep 'provider: efa' | wc -l) -eq 0 ]; then
        echo "EFA or it's dependencies (libfabric) not available"
fi

fi_info -p efa -t FI_EP_RDM
echo "Number of EFA: $(fi_info -p efa -t FI_EP_RDM | grep 'provider: efa' | wc -l)"
export FI_PROVIDER=efa
export NCCL_DEBUG=info
NCCL_LOG=nccl_test.log
/tmp/nccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g ${N_GPUS} > ${NCCL_LOG}
echo "NCCL test dependencies used: $(grep 'NCCL version' ${NCCL_LOG})"
if [[ $(grep -q "NCCL INFO NET/OFI Selected Provider is efa" ${NCCL_LOG} ) -eq 0  && $(grep -q "NCCL INFO Using network AWS Libfabric" ${NCCL_LOG} ) -eq 0 ]]; then
    echo "NCCL tests used EFA";
else
    echo "ERROR: NCCL tests are not detecting and using EFA!"
    exit 1
fi
echo "Dependencies used on NCCL-tests: $(grep 'NCCL version ' ${NCCL_LOG})"
if [[ $(grep 'float' ${NCCL_LOG} | grep sum - | wc -l) -ne 25 ]]; then
    echo "NCCL test results contain errors."
    exit 1
fi
echo "See EFA backed NCCL test results in ${NCCL_LOG}"


################
################
# PyTorch checks
echo "Starting PyTorch tests"

if [[ ! -v PYTORCH_INSTALL_DISABLE ]]; then
    pip3 install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu116
fi

if [[ -v PYTORCH_DISABLE ]]; then
    echo "PyTorch checks disabled"
else
    export NCCL_DEBUG=INFO
    ${1:-python3} -c "import torch;print('CUDA version:', torch.version.cuda, '\n', 'cuDNN version:', torch.backends.cudnn.version(), '\n',  'NCCL version:', torch.cuda.nccl.version())"
    ${1:-python3} run.py local
    TRAINING_LOG=training.log
    ${1:-python3} -m torch.distributed.run --standalone --nnodes=1 --nproc_per_node=${N_GPUS} run.py ddp > ${TRAINING_LOG}
    echo "NCCL and CUDA dependencies used for distributed training: $(grep 'NCCL version' ${TRAINING_LOG})"
    echo "See full distributed training log in ${TRAINING_LOG}"
fi


################
################
# Multi node checks
echo "Starting multi node tests"

if [[ -v MULTINODE_DISABLE ]]; then
    echo "Multi node checks disabled"
    exit 0
else
    NCCL_JOB_ID=$(sbatch --parsable multi_node_nccl.sbatch)
    sleep 120
    NCCL_JOB_LOG=slurm-${NCCL_JOB_ID}.out
    if [[ $(grep 'float' ${NCCL_JOB_LOG} | grep 'float' - | wc -l) -ne 5 || $(grep -q 'Out of bounds values : 0 OK' ${NCCL_JOB_LOG}) -ne 0 ]]; then
        echo "NCCL test results contain errors."
        exit 1
    fi
    echo "NCCL test dependencies used: $(grep 'NCCL version' ${NCCL_JOB_LOG})"

    DDP_JOB_ID=$(sbatch --parsable multi_node_ddp.sbatch)
    sleep 120
    DDP_JOB_LOG=slurm-${DDP_JOB_ID}.out
    echo "DDP test dependencies used: $(grep 'NCCL version' ${DDP_JOB_LOG})"
    for rank_param in 'WORLD_SIZE: 16' 'RANK: 0' 'RANK: 15'; do
        if [[ $(grep -Fxq "${rank_param}" ${DDP_JOB_LOG}) -ne 0 ]]; then
            echo "Rank ${rank_param} not found in DDP job log ${DDP_JOB_LOG}"
            exit 1
        fi
    done

    for i in {0..900..100}; do
        grep -o "step: ${i}" ${DDP_JOB_LOG}
        grep -o "step: ${i}" ${DDP_JOB_LOG} | wc -l
        if [[  $(grep -o "step: ${i}" ${DDP_JOB_LOG} | wc -l) -ne $(( ${N_GPUS} * 2 )) ]]; then
            echo "Step ${i} missing!"
            exit 1
        fi
    done
fi
