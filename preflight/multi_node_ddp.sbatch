#!/bin/bash
#SBATCH --exclusive
#SBATCH --gres=gpu:8
#SBATCH --gpus-per-node=8
#SBATCH --wait-all-nodes=1
#SBATCH --nodes 2
set -ex;


RDV_ADDR=$(hostname)
WORLD_SIZE=$SLURM_JOB_NUM_NODES


srun -l torchrun \
   --nproc_per_node=$SLURM_GPUS_PER_NODE \
   --nnodes=$WORLD_SIZE \
   --rdzv_id=$SLURM_JOB_ID \
   --rdzv_backend=c10d \
   --rdzv_endpoint=$RDV_ADDR \
    run.py ddp
