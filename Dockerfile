FROM ubuntu:16.04

MAINTAINER Lars Tingelstad <lars.tingelstad@ntnu.no>

USER root

RUN apt-get update && apt-get -y install \
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
    libeigen3-dev \
    libsuitesparse-dev \
    clang-3.8 \
    llvm \
    libgtest-dev \
    python-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# RUN cd /usr/src/gtest \
#     cmake CMakeLists.txt \ 
#     make -j10 \ 
#     make install

# RUN cd /usr/src/gtest \
#     sudo cmake . \
#     sudo cmake --build . --target install

ENV CC clang-3.8
ENV CXX clang++-3.8

RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
RUN python get-pip.py pip install --upgrade setuptools
RUN pip install virtualenv

# Install Ceres
RUN mkdir -p /usr/src/ \
    && curl -SL http://ceres-solver.org/ceres-solver-1.11.0.tar.gz \
    | tar -xvzC /usr/src/ \
    && mkdir -p /usr/src/ceres-solver-1.11.0/build \
    && cd /usr/src/ceres-solver-1.11.0/build \
    && cmake -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF .. \
    && make -j12 \
    && make install

# RUN cd /usr/src/ \
#     && git clone https://github.com/google/benchmark.git \
#     && cd benchmark \
#     && git checkout 9913418d323e64a0111ca0da81388260c2bbe1e9 \
#     && cd .. \
#     && mkdir -p /usr/src/benchmark/build/ \
#     && cd /usr/src/benchmark/build/ \
#     && cmake -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_ENABLE_LTO=true .. \
#     && make -j12 \
#     && make install

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y nodejs

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.9.0/tini \
    && echo "faafbfb5b079303691a939a747d7f60591f2143164093727e870b289a44d9872 *tini" | sha256sum -c - \
    && mv tini /usr/local/bin/tini \
    && chmod +x /usr/local/bin/tini

RUN useradd -m -s /bin/zsh -N -u 1000 game



USER game

RUN mkdir -p /home/game/repo/ \
    && cd /home/game/repo/ \
    && git clone https://github.com/juanmed/game.git \
    && cd game \
    && git submodule update --init --recursive \
    && git submodule update --recursive \
    && mkdir build \
    && cd build \
    && cmake .. && make -j10
#    && make install 

RUN mkdir -p /home/game/game/ \
    && mkdir /home/game/.jupyter

   

RUN cd /home/game/ \
    && virtualenv python \
    && . python/bin/activate \
    && pip install \
       numpy \
       matplotlib \
       scipy \
       notebook \
       math3d==3.3.0
       #comm==0.2.1 \
       #pythreejs \
    #&& jupyter nbextension enable --py pythreejs
    # && git clone https://github.com/tingelst/pythreejs.git \
    # && cd pythreejs \
    # && pip install -e . \
    # && jupyter nbextension install --py --symlink --user pythreejs \
    # && jupyter nbextension enable --py --user pythreejs \
    # && jupyter nbextension enable --py --sys-prefix widgetsnbextension

USER root
VOLUME /home/game/game
# Add local files as late as possible to avoid cache busting
# Start notebook server
#COPY jupyter_notebook_config.py /home/game/.jupyter/
RUN chown -R game:users /home/game/.jupyter

USER game
EXPOSE 8888
WORKDIR /home/game/game/python
ENTRYPOINT ["tini", "--"]
CMD ["/bin/zsh", "-c", "source /home/game/python/bin/activate && jupyter notebook --ip 0.0.0.0 --port 8888 --no-browser --allow-root"]
