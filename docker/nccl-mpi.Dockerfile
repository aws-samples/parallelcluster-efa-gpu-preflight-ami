FROM nvidia/cuda:11.6.0-devel-ubuntu20.04
RUN apt update && apt install git wget -y
RUN cd /opt && git clone https://github.com/koyongse/nccl.git && \
        cd nccl && git checkout dynamic-buffer-depth && \
        make -j src.build CUDA_HOME=/usr/local/cuda NVCC_GENCODE='-gencode=arch=compute_70,code=sm_70 -gencode=arch=compute_75,code=sm_75 -gencode=arch=compute_80,code=sm_80'

ARG MPI_VERSION="4.0.2"
ARG MPI_CONFIGURE_OPTIONS="--enable-fast=all,O3 --prefix=/opt/openmpi --with-cuda=/usr/local/cuda"
ARG MPI_MAKE_OPTIONS="-j4"

RUN mkdir -p /tmp/openmpi-build \
      && cd /tmp/openmpi-build \
      && MPI_VER_MM="${MPI_VERSION%.*}" \
      && wget http://www.openmpi.org/software/ompi/v${MPI_VER_MM}/downloads/openmpi-${MPI_VERSION}.tar.bz2 \
      && tar xjf openmpi-${MPI_VERSION}.tar.bz2 \
      && cd openmpi-${MPI_VERSION}  \
      && ./configure ${MPI_CONFIGURE_OPTIONS} \
      && make ${MPI_MAKE_OPTIONS} \
      && make install \
      && ldconfig \
      && cd / \
      && rm -rf /tmp/openmpi-build

RUN git clone https://github.com/NVIDIA/nccl-tests.git /opt/nccl-tests \
    && cd /opt/nccl-tests \
    && make MPI=1 \
       MPI_HOME=/opt/openmpi/ \
       CUDA_HOME=/usr/local/cuda \
       NCCL_HOME=/opt/nccl/build \
       NVCC_GENCODE="-gencode=arch=compute_86,code=sm_86 -gencode=arch=compute_80,code=sm_80 -gencode=arch=compute_75,code=sm_75 -gencode=arch=compute_70,code=sm_70 -gencode=arch=compute_60,code=sm_60"

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/openmpi/lib:/opt/nccl/build/lib
ENV PATH=${PATH}:/opt/openmpi/bin

CMD mpirun --allow-run-as-root -np 8 -x NCCL_DEBUG=INFO /opt/nccl-tests/build/all_reduce_perf -b 8 -e 128M -f 2 -g 1
