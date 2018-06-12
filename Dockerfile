FROM tensorflow/tensorflow:latest-py3

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
      bzip2 \
      g++ \
      git \
      graphviz \
      libgl1-mesa-glx \
      libhdf5-dev \
      openmpi-bin \
      wget && \
    rm -rf /var/lib/apt/lists/*

COPY src /src
COPY entrypoints/entrypoint_local.sh /entrypoint.sh

WORKDIR /src

RUN pip install -r requirements.txt

ENV PYTHONPATH='/src/:$PYTHONPATH'

ENTRYPOINT ["/entrypoint.sh"]
