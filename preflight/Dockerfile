ARG IMAGE=public.ecr.aws/w6p6i9i7/aws-efa-nccl-rdma:22.03-pt-py3
FROM ${IMAGE}
RUN cd /tmp && \
        git clone https://github.com/NVIDIA/nccl-tests.git && \
        cd nccl-tests && \
        make MPI=1 MPI_HOME=/opt/amazon/openmpi CUDA_HOME=/usr/local/cuda NCCL_HOME=/opt/nccl/build
COPY preflight.sh /tmp/
CMD /tmp/preflight.sh python
