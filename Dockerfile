# syntax = docker/dockerfile:1.4
ARG UBUNTU_VERSION=22.04
ARG MAMBAFORGE_VERSION=4.12.0-2

# NOTE: all stages can run in parallel as root user,
# jovyan user created at end for run-time

# -----------------
FROM ubuntu:${UBUNTU_VERSION} as base

WORKDIR /tmp

LABEL org.opencontainers.image.source=https://github.com/pangeo-data/pangeo-docker-images

ENV CONDA_ENV=notebook \
    DEBIAN_FRONTEND=noninteractive \
    NB_USER=jovyan \
    NB_UID=1000 \
    SHELL=/bin/bash \
    LANG=C.UTF-8  \
    LC_ALL=C.UTF-8 \
    CONDA_DIR=/opt/conda

ENV NB_PYTHON_PREFIX=${CONDA_DIR}/envs/${CONDA_ENV} \
    DASK_ROOT_CONFIG=${CONDA_DIR}/etc \
    HOME=/home/${NB_USER}

ENV PATH=${NB_PYTHON_PREFIX}/bin:${CONDA_DIR}/bin:${PATH}

RUN echo ". ${CONDA_DIR}/etc/profile.d/conda.sh ; conda activate ${CONDA_ENV}" > /etc/profile.d/init_conda.sh

RUN <<eot
    echo "Installing Apt-get packages..."
    apt-get update --fix-missing > /dev/null
    apt-get install -y apt-utils wget zip tzdata > /dev/null
    apt-get clean
    rm -rf /var/lib/apt/lists/*
eot

COPY --link apt* .
RUN <<eot
    echo "Checking for 'apt.txt'..."
    if test -f "apt.txt" ; then
      apt-get update --fix-missing > /dev/null
      xargs -a apt.txt apt-get install -y
      apt-get clean
      rm -rf /var/lib/apt/lists/*
    fi
eot

FROM condaforge/mambaforge:${MAMBAFORGE_VERSION} as mambaforge

# -----------------
FROM base as conda

#Install environment from conda-linux-64.lock or environment.yml if they exist
COPY --link --from=mambaforge /opt/conda ${CONDA_DIR}
COPY --link environment.yml* conda-linux-64.lock* requirements.txt* postBuild* .

# NOTE: w/o from=: uses local cache pangeo-mambacache:latest
RUN --mount=type=cache,target=/opt/conda/pkgs <<eot
    echo "Checking for 'conda-linux-64.lock' or 'environment.yml'..."
    if test -f "conda-linux-64.lock" ; then
      mamba create --name ${CONDA_ENV} --file conda-linux-64.lock
    elif test -f "environment.yml" ; then
      mamba env create --name ${CONDA_ENV} -f environment.yml
    else
      echo "No conda-linux-64.lock or environment.yml! *creating default env*"
      mamba create --name ${CONDA_ENV} pangeo-notebook
    fi
    mamba clean -yt
    find ${CONDA_DIR} -not -path "${CONDA_DIR}/pkgs/*" -follow -type f -name '*.a' -delete
    find ${CONDA_DIR} -not -path "${CONDA_DIR}/pkgs/*" -follow -type f -name '*.pyc' -delete
    find ${CONDA_DIR} -not -path "${CONDA_DIR}/pkgs/*" -follow -type f -name '*.js.map' -delete
    if [ -d ${NB_PYTHON_PREFIX}/lib/python*/site-packages/bokeh/server/static ]; then
      find ${NB_PYTHON_PREFIX}/lib/python*/site-packages/bokeh/server/static -follow -type f -name '*.js' ! -name '*.min.js' -delete
    fi
eot

RUN <<eot
    echo "Checking for pip 'requirements.txt'..."
    if test -f "requirements.txt" ; then
      ${NB_PYTHON_PREFIX}/bin/pip install --no-cache -r requirements.txt
    fi
eot

RUN <<eot
    echo "Checking for 'postBuild'..."
    if test -f "postBuild" ; then
      chmod +x postBuild
      ./postBuild
      rm -rf /tmp/*
      rm -rf ${NB_PYTHON_PREFIX}/share/jupyter/lab/staging
      find ${CONDA_DIR} -follow -type f -name '*.a' -delete
      find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete
      find ${CONDA_DIR} -follow -type f -name '*.js.map' -delete
    fi
eot


# -----------------
FROM base as start


# Create executable entrypoint start script if it doesn't exist
COPY --link start* .

RUN <<eot
    echo "Checking for 'start'..."
    if ! test -f "start" ; then
      printf '#!/bin/bash -l\nexec "$@"\n' > start
    fi
    chmod +x start
eot


# -----------------
FROM base as merge

# jovyan user has full permissions to $HOME, $CONDA_DIR
RUN <<eot
    echo "Creating ${NB_USER} user..."
    groupadd --gid ${NB_UID} ${NB_USER}
    useradd --create-home --gid ${NB_UID} --no-log-init --uid ${NB_UID} ${NB_USER}
    chown ${NB_USER}:${NB_USER} ${HOME}
eot

USER ${NB_USER}
WORKDIR ${HOME}

COPY --from=conda --chown=1000:1000 --link ${CONDA_DIR} ${CONDA_DIR}
COPY --from=start --link /tmp/start /opt/start

EXPOSE 8888
ENTRYPOINT ["/opt/start"]
