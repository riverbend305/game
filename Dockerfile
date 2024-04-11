# May need to:
#  sudo apt install docker.io
#  echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
#  sudo systemctl restart docker
#  sudo chmod 666 /var/run/docker.sock
# before 'docker build .  -t tingelst/game'

# Don't install any OS updates so that clang-3.8 will be found
FROM ubuntu:16.04

MAINTAINER Lars Tingelstad <lars.tingelstad@ntnu.no>

ARG DEBIAN_FRONTEND=noninteractive

# su root
# whoami
USER root

RUN apt-get update && apt-get -y install \
    apt-utils \
    wget \
    curl \
    git \
    cmake \
    zsh \
    build-essential \
    ninja-build \
    python-pip \
    libpython-dev \
    libpng-dev\
    libfreetype6-dev \
    libgoogle-glog-dev \
    libatlas-base-dev \
    libsuitesparse-dev \
    clang-3.8 \
    llvm \
    libgtest-dev \
    python-dev \
    python3-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# export CC="clang-3.8"
ENV CC clang-3.8
# export CXX="clang++-3.8"
ENV CXX clang++-3.8

## OS Installed

#RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
#RUN python get-pip.py pip install --default-timeout=100 --upgrade setuptools
#RUN pip install --default-timeout=100 virtualenv
RUN pip install --default-timeout=100 virtualenv==15.1.0

# Install Eigen into /usr/local/include
RUN mkdir -p /usr/src/ \
    && curl -SL https://gitlab.com/libeigen/eigen/-/archive/3.2.9/eigen-3.2.9.tar.gz \
    | tar -xvzC /usr/src/ \
    && mkdir -p /usr/src/eigen-3.2.9/build \
    && cd /usr/src/eigen-3.2.9/build \
	&& cmake .. \
    && make \
	&& make install

# Install Ceres into /usr/local
RUN cd /usr/src/ \
    && curl -SL http://ceres-solver.org/ceres-solver-1.11.0.tar.gz \
    | tar -xvzC /usr/src/ \
    && mkdir -p /usr/src/ceres-solver-1.11.0/build \
    && cd /usr/src/ceres-solver-1.11.0/build \
    && cmake -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF .. \
    && make \
    && make install

## Eigen,Ceres Installed

#Install benchmark into /usr/local
 RUN cd /usr/src/ \
     && curl -SL https://github.com/google/benchmark/archive/refs/tags/v1.1.0.tar.gz \
     | tar -xvzC /usr/src/ \
     && mv benchmark-1.1.0 benchmark \
     && mkdir -p /usr/src/benchmark/build/ \
     && cd /usr/src/benchmark/build/ \
     && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_LTO=true .. \
     && make \
     && make install

## benchmark Installed

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y nodejs

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.9.0/tini \
    && echo "faafbfb5b079303691a939a747d7f60591f2143164093727e870b289a44d9872 *tini" | sha256sum -c - \
    && mv tini /usr/local/bin/tini \
    && chmod +x /usr/local/bin/tini
## Nodejs,Tini Installed

# useradd -m -s /bin/zsh -N -u 1001 game 
RUN useradd -m -s /bin/zsh -N -u 1000 game

# su game , choose 0 option to create ~/.zshrc containing just a comment
# whoami
USER game

RUN mkdir -p /home/game/repo/ \
    && cd /home/game/repo/ \
    && git clone https://github.com/riverbend305/game.git \
    && cd game  \
    && git submodule update --init --recursive \
    && git submodule update --recursive \
    && mkdir build \
    && cd build \
    && cmake .. && make 

## repo built

RUN mkdir -p /home/game/game/ \
    && mkdir /home/game/.jupyter

RUN cd /home/game/ \
    && virtualenv py2env -p /usr/bin/python2 \
    && . py2env/bin/activate \
    # python == 2.7.12, ipython == 5.10.0
    && python -m pip install ipykernel \
    && ipython kernel install --name py2 --user \
       numpy==1.16.0 \
       matplotlib \
       scipy \
       notebook \
    && deactivate \
    && virtualenv py3env -p /usr/bin/python3 \
    && . py3env/bin/activate \
    # python == 3.5.2, ipython == 7.9.0
    && python -m pip install ipykernel \
    && ipython kernel install --name py3 --user \
    && python -m pip install --default-timeout=100 \
       numpy==1.16.0 \
       matplotlib \
       scipy \
       notebook \
       math3d==3.3.0 \
       pandas \
       comm \
    && git clone https://github.com/tingelst/pythreejs.git \
    && cd pythreejs \
    && python -m pip install --default-timeout=100 -e . \
    && jupyter nbextension install --py --symlink --user pythreejs \
    && jupyter nbextension enable --py --user pythreejs \
    && jupyter nbextension enable --py --sys-prefix widgetsnbextension

# Type 'exit' to return to user root
USER root

# cd /home/game/game
VOLUME /home/game/game

# Add local files as late as possible to avoid cache busting
# Start notebook server
RUN chown -R game:users /home/game/.jupyter

# su game , choose 0 option to create ~/.zshrc containing just a comment
# whoami
USER game
EXPOSE 8888
WORKDIR /home/game/repo/game/python
ENTRYPOINT ["tini", "--"]
CMD ["/bin/zsh", "-c", "source /home/game/python3/bin/activate && jupyter notebook --ip 0.0.0.0 --port 8888 --no-browser --allow-root"]
