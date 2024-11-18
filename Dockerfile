FROM condaforge/miniforge3:24.7.1-2

LABEL maintainer="cgphelp@sanger.ac.uk" \
      uk.ac.sanger.cgp="Cancer, Ageing and Somatic Mutation, Wellcome Trust Sanger Institute" \
      version="1.4.3" \
      description="cgp-methpipe_1.4.3"

ENV OPT /opt/wtsi-cgp
ENV USER=service
ENV DEBIAN_FRONTEND=noninteractive 

ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL C
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# INSTALL APT DEPENDENCIES

RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
    build-essential \
    apt-transport-https \
    curl \
    ca-certificates \
    default-jre \
    nodejs \
	npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# INSTALL STANDALONE

RUN npm install -g standalone-html

# INSTALL CONDA PACKAGES

# create a python 2.7 environment
RUN mamba create -n py27 python=2.7 -c conda-forge -y

# install conda packages
COPY environment.yml /
RUN conda run -n py27 mamba env update -f /environment.yml --prune && \
    conda clean -a

# make sure installed packages are executable
RUN chmod -R a+rx /opt/conda/envs/py27/bin

# INSTALL OPT

RUN mkdir -p $OPT/bin
ADD build/opt-build.sh build/
RUN bash build/opt-build.sh $OPT
COPY ./bin/ $OPT/bin/
RUN chmod -R a+rx $OPT

# SET USER AND PATH

RUN adduser --disabled-password --gecos '' $USER && chsh -s /bin/bash && mkdir -p /home/$USER
USER $USER
WORKDIR /home/$USER
RUN sed -i '/conda activate /d' ~/.bashrc
ENV PATH=/opt/wtsi-cgp:/opt/wtsi-cgp/bin:/opt/conda/envs/py27/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ADD METHYLSEQ SCRIPTS

RUN git clone --branch 1.4 https://github.com/nf-core/methylseq.git
