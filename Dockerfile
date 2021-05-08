FROM ubuntu:18.04 as builder
LABEL description="Builder of sample project on Ubuntu"

#environment variables
ENV PROJECT_DIR="/project" \
    BUILD_TYPE=RELEASE \
    CMAKE_VERSION=3.13.3 \
    PATH=/opt/cmake/bin:${PATH} \
    CMAKE_PREFIX_PATH=/usr/local/lib:/usr/local/lib64:${CMAKE_PREFIX_PATH} \
    LD_LIBRARY=/usr/local/lib:/usr/local/lib64:${LD_LIBRARY}

ENV TZ=Europe/Minsk
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#basic dependencies.
#compile dependencies
#software-properties-common for add-apt-repository
#ca-certificates for verification

RUN apt-get update && apt-get install -y \
    software-properties-common \
    ca-certificates \
    build-essential \
    mesa-utils \
    glmark2 \
    # cmake \
    sudo \
    vim \
    git \
    tar \
    unzip \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*
    

#gcc8
RUN add-apt-repository -y ppa:jonathonf/gcc && \
    apt-get update && \
    apt-get install -y gcc-8 g++-8 && \
    rm -rf /usr/bin/gcc /usr/bin/g++ && \
    ln -s /usr/bin/g++-8 /usr/bin/g++ && \
    ln -s /usr/bin/gcc-8 /usr/bin/gcc \
    && rm -rf /var/lib/apt/lists/*
    

#cmake
RUN mkdir -p /opt &&\
    curl -jksSL https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz | tar -xzf - -C /opt &&\
    mv -f /opt/cmake-${CMAKE_VERSION}-Linux-x86_64 /opt/cmake


#boost1.68
# WORKDIR /3rdparty
# RUN wget -O boost_1_68_0.tar.gz https://dl.bintray.com/boostorg/release/1.68.0/source/boost_1_68_0.tar.gz &&\
#     tar xzvf boost_1_68_0.tar.gz &&\
#     cd boost_1_68_0/ &&\
#     ./bootstrap.sh --prefix=/opt/boost_1_68_0 &&\
#     ./b2 -j12&&\
#     ./b2 install 
    
#protobuf qt ssh eigen yaml-cpp
RUN apt-get update && apt-get install -y \
    libboost-all-dev \
    libprotobuf-dev \
    protobuf-compiler \
    qt5-default \
    qttools5-dev-tools \
    libqt5opengl5-dev \
    libssh-dev \
    libyaml-cpp-dev \
    libpcl-dev \
    libceres-dev \
    libopencv-dev \
    libeigen3-dev \
    libflann-dev \
    libusb-1.0-0-dev \
    libvtk6-qt-dev \
    libpcap-dev \
    libproj-dev \
    gdb \
    gdbserver \
    && rm -rf /var/lib/apt/lists/*


#osg(dynamic)
# RUN git clone --branch pcl-1.8.0 --depth 1 https://github.com/PointCloudLibrary/pcl.git pcl-trunk && \
#      cd pcl-trunk && \
#     mkdir build && cd build && \
#     cmake -DCMAKE_BUILD_TYPE=Release .. && \
#     make -j 4 && make install && \
#     make clean

# RUN ls /usr/lib/x86_64-linux-gnu/libboost_system*
WORKDIR /3rdparty
#osg(dynamic)
RUN git clone --branch OpenSceneGraph-3.6 --depth 1 https://gitee.com/neophack/OpenSceneGraph && \
    cd OpenSceneGraph  && mkdir build && cd build \
    && cmake .. && make -j12 && make install &&   make clean

#draco(static)
RUN git clone https://gitee.com/neophack/draco && \
    cd draco && mkdir build && cd build \
    && cmake .. && make -j12 && make install &&    make clean
    
#Installing libnabo:
RUN git clone https://gitee.com/neophack/libnabo &&\
    cd libnabo && mkdir build && cd build && cmake .. && make -j12&& make install &&    make clean

#Installing libpointmatcher:
RUN git clone https://gitee.com/neophack/libpointmatcher && \
   cd libpointmatcher && mkdir build && cd build && cmake .. && make -j12 && make install &&   make clean

#Installing steam:
RUN git clone https://github.com/utiasASRL/steam.git &&\
    cd steam && git submodule update --init --remote &&\
    mkdir -p build/catkin_optional && cd build/catkin_optional &&\
    cmake ../../steam/deps/catkin/catkin_optional && make -j12 &&\
    cd ../.. && mkdir -p build/catch && cd build/catch &&\
    cmake ../../steam/deps/catkin/catch && make -j12 &&\
    cd ../.. && mkdir -p build/lgmath && cd build/lgmath &&\
    cmake ../../steam/deps/catkin/lgmath && make -j12 &&\
    cd ../.. && mkdir -p build/steam && cd build/steam &&\
    cmake ../../steam && make -j12 &&\
    cd build/steam &&\
    sudo make install &&   make clean
    
ADD ["start.sh", "/app/"]
#clean up
RUN rm -rf /var/lib/apt/lists/* &&\
    chmod u+x /app/start.sh &&\
    mkdir /project &&\
    ldconfig &&\
    cp -s /usr/local/lib/libOpenThreads.so.21 /usr/lib

VOLUME ["/project"]

WORKDIR /project/build
ENTRYPOINT ["/app/start.sh"]
