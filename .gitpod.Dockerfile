FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

ADD https://raw.githubusercontent.com/gitpod-io/workspace-images/main/base/install-packages /usr/local/bin/install-packages
RUN chmod +x /usr/local/bin/install-packages

RUN install-packages wget ca-certificates gnupg curl sudo

ADD https://gist.githubusercontent.com/aledbf/eb99f18ee60a139de36739a2d17a9846/raw/84215df2ff22ff59fe92e85eac1b6ba0db8e97dd/gitpod-gpu.sh /usr/local/bin/gitpod-gpu.sh
RUN chmod +x /usr/local/bin/gitpod-gpu.sh
RUN /usr/local/bin/gitpod-gpu.sh

ARG PIP_DISABLE_PIP_VERSION_CHECK=1
ARG PIP_NO_CACHE_DIR=1

# Ubuntu packages
RUN install-packages python3 python3-pip wget \
  && python3 -m pip install --upgrade pip \
  && install-packages -y python3-dev git curl nodejs

RUN pip install --upgrade jupyter \
  && pip install --upgrade jupyterlab \
  && pip install jupyter_contrib_nbextensions \
  && jupyter contrib nbextension install --user \
  && jupyter nbextensions_configurator enable --user \
  && jupyter nbextension enable collapsible_headings/main --user

RUN curl -s http://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
  && sh -c "echo deb http://deb.nodesource.com/node_18.x focal main > /etc/apt/sources.list.d/nodesource.list" \
  && install-packages nodejs \
  && node --version

### Jupyterlab extensions
RUN pip install --upgrade jupyterlab-git jupyterlab-quickopen aquirdturtle_collapsible_headings
# Jupyterlab lsp
RUN jupyter lab build
# Environmental variables for wandb
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# General pip packages
RUN pip install --upgrade twine keyrings.alt pynvml fastgpu
# Add ipython_config.py in /etc/ipython
RUN mkdir /etc/ipython \
  && echo "c.Completer.use_jedi = False" > /etc/ipython/ipython_config.py

# INSTALL CUDNN8
#RUN apt-get update && apt-get install -y --no-install-recommends --allow-change-held-packages libcudnn8 fonts-powerline \
#  && apt-mark hold libcudnn8 \
#  && rm -rf \
#    /var/cache/debconf/* \
#    /var/lib/apt/lists/* \
#    /tmp/* \
#    /var/tmp/*


# UPDATE JUPYTERLAB to 3.x (plotly visualization and pre-built debugger are now supported) ipkykernel>=6 is required
RUN pip3 install --upgrade jupyterlab jupyterlab-git nbdime aquirdturtle_collapsible_headings jupyterlab_widgets jupyterlab-quickopen ipykernel \
  # JUPYTERLAB additional extension for CPU, Memory, GPU usage and new themes
  && pip3 install jupyterlab_nvdashboard jupyterlab-logout jupyterlab-system-monitor jupyterlab-topbar \
                 jupyterlab_theme_hale jupyterlab_theme_solarized_dark nbresuse \
                 jupyter-lsp jupyterlab-drawio jupyter-dash jupyterlab_code_formatter black isort jupyterlab_latex \
                 xeus-python theme-darcula jupyterlab_materialdarker lckr-jupyterlab-variableinspector \
  && jupyter labextension install jupyterlab-chart-editor \
# Required for Dash
  && jupyter lab build \
  && pip3 install scikit-learn fastgpu nbdev pandas transformers tensorflow-addons tensorflow pymongo emoji python-dotenv plotly

RUN pip3 install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cu117

EXPOSE 8888

# Install:
# - git (and git-lfs), for git operations (to e.g. push your work).
#   Also required for setting up your configured dotfiles in the workspace.
# - sudo, while not required, is recommended to be installed, since the
#   workspace user (`gitpod`) is non-root and won't be able to install
#   and use `sudo` to install any other tools in a live workspace.
RUN install-packages \
    git \
    git-lfs \
    sudo

# Create the gitpod user. UID must be 33333.
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod

USER gitpod