FROM node:18-buster
ARG PCLUSTER_VERSION=3.3.0
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o get_pip.py && python3 get_pip.py && rm get_pip.py && \
    python3 -m pip install "aws-parallelcluster==${PCLUSTER_VERSION}" --user
ENV PATH="/root/.local/bin:${PATH}"
