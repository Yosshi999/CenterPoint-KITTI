FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        ca-certificates wget git vim && \
# ==================================================================
# python prerequisites
# ==================================================================
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential libbz2-dev libdb-dev \
        libreadline-dev libffi-dev libgdbm-dev liblzma-dev \
        libncursesw5-dev libsqlite3-dev libssl-dev \
        zlib1g-dev uuid-dev tk-dev && \
# ==================================================================
# pymodule prerequisities
# ==================================================================
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        libsparsehash-dev libblas-dev liblapack-dev libhdf5-dev && \
# ==================================================================
# python 3.9 via apt
# ==================================================================
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        python3.9 python3.9-dev python3.9-distutils && \
    wget -O ~/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python3.9 ~/get-pip.py && \
    ln -s /usr/bin/python3.9 /usr/local/bin/python3 && \
    ln -s /usr/bin/python3.9 /usr/local/bin/python && \
    $PIP_INSTALL setuptools && \
    $PIP_INSTALL numpy Cython && \
# ==================================================================
# pytorch 1.10 via pip
# ==================================================================
    $PIP_INSTALL "torch>=1.10" torchvision && \
# ==================================================================
# cleanup
# ==================================================================
    ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

WORKDIR /app
# ==================================================================
# cmake
# ==================================================================
RUN wget https://github.com/Kitware/CMake/releases/download/v3.21.1/cmake-3.21.1.tar.gz && \
    tar zxvf cmake-3.21.1.tar.gz && \
    cd cmake-3.21.1/ && \
    ./bootstrap && \
    make && make install && \
    cd ../ && \
    rm -rf ./cmake-3.21.1.tar.gz
ENV PATH /app/cmake-3.21.1/bin:$PATH

# ==================================================================
# spconv 1.2.1 (fad3000)
# ==================================================================
RUN wget https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.gz && \
    tar xzvf boost_1_76_0.tar.gz && \
    cp -r ./boost_1_76_0/boost /usr/include && \
    rm -rf ./boost_1_76_0 && \
    rm -rf ./boost_1_76_0.tar.gz
RUN git clone https://github.com/traveller59/spconv.git --recursive
# ==================================================================
# Env for cuda compiler. See https://github.com/pytorch/extension-cpp/issues/71
# How to find your GPU's CC: https://developer.nvidia.com/cuda-gpus
# ==================================================================
ARG TORCH_CUDA_ARCH_LIST="7.5+PTX"
ENV SPCONV_FORCE_BUILD_CUDA 1
RUN cd ./spconv && git checkout fad3000 && git submodule update --recursive && python setup.py bdist_wheel && pip install ./dist/spconv*.whl

# ==================================================================
# main
# ==================================================================
RUN mkdir -p /app/centerpoint
WORKDIR /app/centerpoint

COPY requirements.txt setup.py ./
COPY pcdet/ /app/centerpoint/pcdet/
RUN pip install -r requirements.txt && \
    python setup.py develop

COPY tools/ /app/centerpoint/tools/

# ==================================================================
# other pymodule
# ==================================================================
RUN PIP_INSTALL="python -m pip --no-cache-dir install --upgrade" && \
    $PIP_INSTALL \
        six

ENV PYTHONPATH=/app/centerpoint