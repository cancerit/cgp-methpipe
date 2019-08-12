FROM nfcore/methylseq:1.3

#ENV OPT /opt/wtsi-cgp
#ENV PATH $OPT/bin:$PATH

RUN apt-get -yq update
RUN apt-get install -yq --no-install-recommends \
  build-essential\
  apt-transport-https\
  curl\
  ca-certificates \
  default-jre

#RUN mkdir -p $OPT/bin

ADD build/opt-build.sh build/
RUN bash build/opt-build.sh /usr/

LABEL maintainer="cgphelp@sanger.ac.uk" \
      uk.ac.sanger.cgp="Cancer, Ageing and Somatic Mutation, Wellcome Trust Sanger Institute" \
      version="v1.0.0" \
      description="cgp-methpipe docker"
