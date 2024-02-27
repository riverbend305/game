![](game_logo.png)

# **G**eometric **A**lgebra **M**ultivector **E**stimation

GAME is framework for estimation of multivectors in geometric algebra with focus on, but not limited to, the Euclidean and conformal model.

## Docker
Build
```
docker build . -t tingelst/game
```
Run jupyter notebook
```
docker run -it -v /home/<your-user-name>/path/to/game:/home/game/game -p 8888:8888 tingelst/game:latest
```
Run a command line terminal within the docker container:
```
sudo docker run -v /home/<your-user-name>/repos/game:/home/game/repo/game -ti tingelst/game:latest /bin/bash -c "exec "${SHELL:-sh}""
```
If a docker container is running and you want to open a terminal
```
docker ps # See running containers
# Open a terminal within the container, assuming the name of container is nervous_heyrovsky
docker exec -it nervous_heyrovsky sh 
```

This will run jupyter notebook and show a link that you can follow in your browser to all the python notebooks.

## Installation

The main external dependency of GAME is the Ceres optimization framework from Google.

On OSX we recommend building the homebrew formula from source:
``` bash
brew tap homebrew/science
brew install ceres-solver --build-from-source
```

On Linux we recommend following the installation instructions found here: http://ceres-solver.org/building.html.

To build GAME follow the steps below:
``` bash
$ git clone --recursive https://github.com/tingelst/game.git
$ cd game
$ mkdir build && cd build
$ cmake .. && make
```
