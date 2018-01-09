# Docker image that provides an enviroment for RL.
# The following dependencies will be installed:
# * PyTorch
# * Miniconda
# * Cuda
# * OpenAI Gym
# * MuJoCo (mujoco-py)
# * pysc2
#
# The following ports are exposed:
# * 5902 - VNC (forwards to 5900 of the container)
# * 8888 - IPython (forwards to 8888 of the container)
#
# Run command:
# nvidia-docker run -it -p 5902:5900 -p 8888:8888 -v /private/home/denisy/workspace:/workspace/code --rm rlenv

# Based on Ubuntu 16.04 with Cuda 8
FROM nvidia/cuda:8.0-devel-ubuntu16.04

LABEL maintainer="denisyarats@gmail.com"

# Expose ports for IPython and VNC
EXPOSE 5900 8888

ENV LANG C.UTF-8

# Install dependencies
RUN apt-get update -q && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-utils \
  curl \
  git \
  wget \
  unzip \
  vim \
  net-tools \
  cmake \
  libglew-dev \
  libosmesa6-dev \
  libgtk2.0-0 \
  libav-tools \
  x11vnc \
  xorg-dev \
  libglu1-mesa \
  libgl1-mesa-dev \
  xvfb \
  libxinerama1 \
  libgl1-mesa-glx \
  libxcursor1 \
  lxde-core \
  lxterminal \
  tightvncserver \
  xpra \
  xserver-xorg-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/patchelf https://s3-us-west-2.amazonaws.com/openai-sci-artifacts/manual-builds/patchelf_0.9_amd64.elf \
  && chmod +x /usr/local/bin/patchelf

# Install Miniconda
RUN wget --no-check-certificate --quiet https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
  /bin/bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda && \
  rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH /opt/miniconda/bin:$PATH

# Install MuJoCo
RUN mkdir -p /root/.mujoco && \
  wget https://www.roboti.us/download/mjpro131_linux.zip -O mujoco.zip && \
  unzip mujoco.zip -d /root/.mujoco && \
  rm mujoco.zip
COPY ./mjkey.txt /root/.mujoco/
ENV LD_LIBRARY_PATH /root/.mujoco/mjpro131/bin:$LD_LIBRARY_PATH

# Create conda env and install dependencies
RUN conda create -n py36 anaconda python=3.6
RUN conda install --name py36 numpy
RUN conda install --name py36 pytorch torchvision -c pytorch
RUN /bin/bash -c "source activate py36 && pip install gym[mujoco] tqdm visdom pysc2"

# Install SC2
RUN wget http://blzdistsc2-a.akamaihd.net/Linux/SC2.3.16.1.zip && \
  unzip -P iagreetotheeula SC2.3.16.1.zip -d ~/ && \
  wget http://blzdistsc2-a.akamaihd.net/MapPacks/Ladder2017Season1.zip && \
  wget http://blzdistsc2-a.akamaihd.net/MapPacks/Ladder2017Season2.zip && \
  wget http://blzdistsc2-a.akamaihd.net/MapPacks/Ladder2017Season3.zip && \
  wget http://blzdistsc2-a.akamaihd.net/MapPacks/Melee.zip && \
  unzip -P iagreetotheeula Ladder2017Season1.zip -d ~/StarCraftII/Maps && \
  unzip -P iagreetotheeula Ladder2017Season2.zip -d ~/StarCraftII/Maps && \
  unzip -P iagreetotheeula Ladder2017Season3.zip -d ~/StarCraftII/Maps && \
  unzip -P iagreetotheeula Melee.zip -d ~/StarCraftII/Maps && \
  rm *.zip && \
  echo "wget http://blzdistsc2-a.akamaihd.net/ReplayPacks/3.16.1-Pack_1-fix.zip && unzip -P iagreetotheeula 3.16.1-Pack_1-fix.zip -d ~/StarCraftII/Replays" > download_replays.sh

COPY ./vendor/10_nvidia.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json

RUN mkdir /opencv && \
  curl -fsSL http://bit.ly/OpenCV-Latest | bash -s /opencv-build && \
  rm -rf /opencv-build

ENV PYTHONPATH=$PYTHONPATH:$HOME/.opencv/lib/python3.2/dist-package

WORKDIR /workspace

# Copy VNC script that handles restarts and make it executable
COPY ./vendor/Xdummy /usr/local/bin/Xdummy
RUN chmod +x /usr/local/bin/Xdummy
COPY ./vendor/Xdummy-entrypoint /opt/

# Launch anaconda on start
RUN echo "source activate py36" >> /root/.bashrc
# Launch VNC server on start
RUN echo "x11vnc -display :0 -noxrecord -noxfixes -noxdamage -forever -passwd 123456 -bg -xkb" >> /root/.bashrc

# Entry point to start Xdummy
ENTRYPOINT ["/opt/Xdummy-entrypoint"]
