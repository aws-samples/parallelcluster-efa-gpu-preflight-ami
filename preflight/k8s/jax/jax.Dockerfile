FROM public.ecr.aws/w6p6i9i7/aws-efa-nccl-rdma:22.03-pt-py3
RUN git clone https://github.com/huggingface/transformers.git && \
    cd transformers && \
    git checkout v4.27.3 && \
    python -m pip install -e . && \
    cd examples/flax/question-answering/ && \
    mkdir ./bert-qa-squad && \
    python -m pip install -r requirements.txt && \
    python -m pip install datasets huggingface-hub sacrebleu evaluate && \
    python -m pip install "jax[cuda11_cudnn82]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

ENV FI_EFA_USE_DEVICE_RDMA=1
ENV FI_PROVIDER=efa
ENV RDMAV_FORK_SAFE=1
ENV NCCL_PROTO=simple 
COPY run.py /workspace/transformers/examples/flax/question-answering/run_qa_custom.py
COPY run.sh /workspace/transformers/examples/flax/question-answering/
COPY synthetic.py /tmp/
COPY synthetic.sh /tmp/