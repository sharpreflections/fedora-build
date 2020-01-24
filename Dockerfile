FROM centos:8 AS base
LABEL maintainer="dennis.brendel@sharpreflections.com"

ARG prefix=/opt
WORKDIR /build/

FROM base AS build-cmake
RUN echo "Downloading cmake 3.11.4:" && curl --remote-name --progress-bar https://cmake.org/files/v3.11/cmake-3.11.3-Linux-x86_64.tar.gz && \
    echo "Downloading cmake 3.14.7:" && curl --remote-name --progress-bar https://cmake.org/files/v3.14/cmake-3.14.7-Linux-x86_64.tar.gz && \
    for file in *; do echo -n "Extracting $file: " && tar --directory=$prefix/ -xf $file && echo "done"; done && \
    # strip the dir name suffix '-Linux-x86_64' from each cmake installation
    for dir in $prefix/*; do mv $dir ${dir%-Linux-x86_64}; done && \
    rm -rf /build/*

FROM base AS build-protobuf
RUN yum -y install @development && \
    echo "Downloading protobuf 3.0.2:" && curl --progress-bar https://codeload.github.com/protocolbuffers/protobuf/tar.gz/v3.0.2 --output protobuf-3.0.2.tar.gz && \
    echo "Downloading protobuf 3.5.2:" && curl --progress-bar https://codeload.github.com/protocolbuffers/protobuf/tar.gz/v3.5.2 --output protobuf-3.5.2.tar.gz && \
    for file in *; do echo -n "Extracting $file: " && tar -xf $file && echo "done"; done && \
    cd protobuf-3.0.2 && \
    ./autogen.sh && \
    ./configure --prefix=$prefix/protobuf-3.0 && \
    make --jobs=$(nproc --all) && make install && \
    cd .. && \
    cd protobuf-3.5.2 && \
    ./autogen.sh && \
    ./configure --prefix=/opt/protobuf-3.5 && \
    make --jobs=$(nproc --all) && make install && \
    rm -rf /build/*

FROM base AS production
COPY --from=build-cmake $prefix $prefix
COPY --from=build-protobuf $prefix $prefix
# Our build dependencies                                                                                             
RUN yum -y install xorg-x11-server-utils libX11-devel libSM-devel libxml2-devel libGL-devel \
                   libGLU-devel libibverbs-devel freetype-devel which && \
    # we need some basic fonts and manpath for the mklvars.sh script
    yum -y install urw-fonts man && \
    # Requirements for using epel
    yum -y install yum-utils epel-release.noarch && \
    # clang, gcc and svn
    yum -y install @llvm-toolset @development libomp-devel gcc-gfortran subversion cmake && \
    # Misc (developer) tools
    yum -y install strace valgrind bc joe vim nano mc psmisc && \
    yum clean all

