FROM nfcore/methylseq:1.3

ENV OPT /opt/wtsi-cgp
ENV PATH $OPT/bin:$PATH
ENV LD_LIBRARY_PATH $OPT/lib
ENV LC_ALL C
ENV USER=service

RUN apt-get -yq update
RUN apt-get install -yq --no-install-recommends \
  build-essential\
  apt-transport-https\
  curl\
  ca-certificates \
  default-jre

LABEL maintainer="cgphelp@sanger.ac.uk" \
      uk.ac.sanger.cgp="Cancer, Ageing and Somatic Mutation, Wellcome Trust Sanger Institute" \
      version="v1.0.0" \
      description="cgp-methpipe docker"

RUN adduser --disabled-password --gecos '' $USER && chsh -s /bin/bash && mkdir -p /home/$USER


RUN mkdir -p $OPT/bin
ADD build/opt-build.sh build/
RUN bash build/opt-build.sh $OPT
RUN chmod -R a+rx $OPT
RUN chmod -R a+rx /opt/conda/bin

# Become the final user
USER $USER

WORKDIR /home/$USER

ENV PATH $OPT:/opt/conda/bin:$PATH
ENV NXF_HOME /home/service/.nextflow
RUN nextflow pull http://github.com/nf-core/methylseq -r 1.3
