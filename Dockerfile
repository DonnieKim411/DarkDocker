FROM nvidia/cuda:10.2-cudnn8-devel-ubuntu18.04 as darknet

LABEL maintainer="Donnie Kim, Donnie Kim <donnie.d.kim@loram.com"

ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && apt-get -y upgrade

RUN apt-get -y install build-essential git libopencv-dev

WORKDIR /workspace
RUN git clone https://github.com/AlexeyAB/darknet.git
WORKDIR /workspace/darknet

############# EDIT darkent MAKEFILE #############
# CHANGE OPTIONS HERE. 
# THE CODE BELOW CHANGES OPTTIONS IN MAKEFILE in darknet REPO. I HIGHLY SUGGEST READING MAKEFILE B4 EDITTING HERE
# For example, if you want GPU=0 to be GPU=1, then s/GPU=0/GPU=1/1. THIS PART IS TOTALLY UPTO USER'S CHOICE
# DEFAULT GPU=0, CUDNN=1, CUDNN_HALF=1, OPENCV=1, LIBSO=1
RUN sed -i -e 's/GPU=0/GPU=1/1' -e 's/CUDNN=0/CUDNN=1/1' -e 's/CUDNN_HALF=0/CUDNN_HALF=1/1' -e 's/OPENCV=0/OPENCV=1/1' -e 's/LIBSO=0/LIBSO=1/1' Makefile

# CHANGE HERE BASED ON YOUR GPU CAPABILITY. FOR EXAMPLE, IF YOU ARE USING RTX30XX SERIES, THEN '/arch=compute_75/s/^#//1'
# DEFAULT compute_75 (i.e. RTX 20xx series and QUADRO RTX series in general)
RUN sed -i '/arch=compute_75/s/^#//1' Makefile

RUN make
RUN cp libdarknet.so /usr/local/lib/
RUN cp include/darknet.h /usr/local/include/
RUN ldconfig

################### DARK HELP #########################
FROM darknet as DarkHelp

RUN apt-get install -y cmake build-essential libtclap-dev libmagic-dev 

WORKDIR /workspace
RUN git clone https://github.com/stephanecharette/DarkHelp.git
WORKDIR /workspace/DarkHelp/build

RUN cmake -DCMAKE_BUILD_TYPE=Release ..

RUN make 
RUN make package && dpkg -i darkhelp*.deb

################### DARK MARK #########################
FROM DarkHelp as DarkMark
RUN apt-get install -y libx11-dev libfreetype6-dev libxrandr-dev libxinerama-dev libxcursor-dev
WORKDIR /workspace
RUN git clone https://github.com/stephanecharette/DarkMark.git
WORKDIR /workspace/DarkMark/build

RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make
RUN make package && dpkg -i darkmark*.deb

WORKDIR /workspace
