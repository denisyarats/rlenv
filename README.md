# RLEnv - docker image to deploy an RL environment
This docker image provides an easy way to rollout an Ubuntu 16.04 enviroment that is suitable for RL. It contains many preinstalled libraries, and allows VNC and IPython Notebook access. The following tools are preinstalled in the image:
* Anaconda Python 3.6
* PyTorch 0.3
* CUDA 8.0
* OpenAI Gym 0.9.4
* MuJoCo 1.31 (in order to use MuJoCo you need to put your key ``mjket.txt`` into the root folder)
* pysc2 1.2
* VNC
* Visdom

# Rollout
Make sure you install [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) to work with this image. Then, you can create a container by running:
```
nvidia-docker build -t rlenv .
```
And start the container via:
```
nvidia-docker run -v {LOCAL_CODE_DIR}:/workspace/code -it -p 5902:5900  -p 8888:8888 -p 8097:8097 --rm rlenv
```
This will run the container, open up VNC port (5902) and ipython notebook port (8888), as well as mount a local folder of your choice (need to replace ``{LOCAL_CODE_DIR}``) to the container's ``/workspace/code``. You will be directed to a shell with Anaconda enviroment (Python 3.6) enabled.
