FROM centos:7
LABEL maintainer "Andreas Wilke <wilke@mcs.anl.gov> ;\
                  Luke Van Roekel <luke.vanroekel@gmail.com>"

RUN yum -y update && yum -y upgrade &&  yum -y install \
  bzip2 \
  bzip2-devel \
  cmake \
  csh \
  development \
  dpkg-devel \
  expat-devel \
  file \
  gcc \
  gcc-c++ \
  gdbm-devel \
  git \
  groupinstall \
  kernel-devel \
  less \
  libmpc-devel.x86_64 \
  libxml2 \
  libxml2-devel \
  libxml2-python \
  libxslt \
  libxslt-devel  \
  m4 \
  make \
  mpfr-devel.x86 \
  openssl-devel \
  python-pip \
  readline-devel \
  sqlite-devel \
	tcl \
  tcl-devel \
	tk \
  tk-devel \
  wget \
  which \
  yum-utils \
  zlib-devel \
  && rm -rf /var/lib/apt/lists/* \
  && yum clean all
   
	

# Build and download directory, clean up
WORKDIR /Downloads

# Build GCC 5.3
# get from:
# wget http://mirrors.concertpass.com/gcc/releases/gcc-5.3.0/gcc-5.3.0.tar.gz
# wget http://mirrors-usa.go-parts.com/gcc/releases/gcc-5.3.0/gcc-5.3.0.tar.gz
RUN wget http://mirrors.concertpass.com/gcc/releases/gcc-5.3.0/gcc-5.3.0.tar.gz && \
  tar -xf gcc-5.3.0.tar.gz && \
  mkdir -p /gcc && \
  mkdir tmp && \
  cd tmp && \
  /Downloads/gcc-5.3.0/configure \
  --prefix /gcc \
  --enable-languages=c,c++,fortran \
  --disable-multilib && \
  make -j "$(nproc)" && \
  make install && \
  cd /Downloads && \
  rm -rf *
ENV PATH /gcc:/gcc/bin:$PATH

# CMAKE 3.7.1
WORKDIR /
RUN wget https://cmake.org/files/v3.7/cmake-3.7.1.tar.gz && \
 tar -xvf cmake-3.7.1.tar.gz && \
 cd cmake-3.7.1 && \
 cmake . && \
 make && \
 make install && \
 cd / && \
 rm cmake-3.7.1.tar.gz
ENV PATH /cmake-3.7.1.bin:$PATH

# gcc
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/gcc/lib64/

# MPICH 3.1.4
WORKDIR /Downloads
RUN wget http://www.mpich.org/static/downloads/3.1.4/mpich-3.1.4.tar.gz && \
    tar -xvf mpich-3.1.4.tar.gz && \
    mkdir /mpich3 && \
    cd mpich-3.1.4 && \
    ./configure --prefix=/mpich3 && \
    make && \
    make install && \
    cd /Downloads && rm -rf *
ENV PATH $PATH:/mpich3/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/mpich3/lib/

# OPENMPI 2.0.2
RUN wget https://www.open-mpi.org/software/ompi/v2.0/downloads/openmpi-2.0.2.tar.gz && \
    tar -xvf openmpi-2.0.2.tar.gz && \
    mkdir /openmpi2 && \
    cd openmpi-2.0.2 && \
    ./configure --prefix=/openmpi2 && \
    make all install && \
    cd /Downloads && rm -rf *

# HDF5 1.8.18
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.18/src/hdf5-1.8.18.tar && \
    tar -xvf hdf5-1.8.18.tar && \
    mkdir /hdf5 && \
    cd /Downloads/hdf5-1.8.18 && \
    ./configure --prefix=/hdf5 --enable-fortran && \
    make && make check && \
    make install && make check-install && \
    cd /Downloads && rm -rf *
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/hdf5/lib
ENV PATH $PATH:/hdf5/bin

# netCDF 4.4.1.1
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.1.1.tar.gz && \
    tar -xvf netcdf-4.4.1.1.tar.gz && \
    mkdir /netcdf4 && \
    cd /Downloads/netcdf-4.4.1.1 && \
    CPPFLAGS=-I/hdf5/include LDFLAGS=-L/hdf5/lib ./configure --prefix=/netcdf4 && \
    make all check && \
    make install && \
    cd /Downloads && rm -rf *
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/netcdf4/lib/


# pFUnit git:master
ENV F90_VENDOR=GNU F90=gfortran MPIF90=mpif90 PFUNIT=/pFUnit
RUN git clone git://git.code.sf.net/p/pfunit/code pFUnit && \
  mkdir -p pFUnit/build /pFUnit && \
  cd pFUnit/build && \
  cmake -DMPI=YES -DOPENMP=NO -DINSTALL_PATH=/pfUnit -DCMAKE_INSTALL_PREFIX=/pFUnit ../ && \
  make tests && \
  make install INSTALL_DIR=/pFUnit && \
  mkdir /pFUnit/Examples && \
  cp -r ../Examples /pFUnit/Examples && \
  cd /Downloads && rm -rf *
ENV PATH /pFUnit/bin:$PATH
ENV PFUNIT /pFUnit






# Install Netcdf c++ bindings
WORKDIR /Downloads
ENV PREFIX /netcdf4
ENV CFLAGS="-I$PREFIX/include $CFLAGS" \
    CPPFLAGS="-I$PREFIX/include $CPPFLAGS" \
    LDFLAGS="-L$PREFIX/lib $LDFLAGS"
RUN wget http://www.gfd-dennou.org/library/netcdf/unidata-mirror/netcdf-cxx-4.2.tar.gz && \
    tar -xzvf netcdf-cxx-4.2.tar.gz && \
    cd netcdf-cxx-4.2 && \
    ./configure \
    --enable-static \
    --enable-shared \
    --prefix=$PREFIX && \
    make && \
    make install && \
    cd .. && \
    rm -rf *
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/netcdf4/lib
ENV PATH $PATH:/netcdf4/bin

# Install netcdf fortran bindings
RUN wget http://www.gfd-dennou.org/library/netcdf/unidata-mirror/netcdf-fortran-4.4.2.tar.gz && \
    tar -xzvf netcdf-fortran-4.4.2.tar.gz && \
    cd netcdf-fortran-4.4.2 && \
    ./configure \
    --enable-static \
    --enable-shared \
    --prefix=$PREFIX && \
    make && \
    make install && \
    cd .. && \
    rm -rf *

# Install parallel netcdf
ENV PREFIX /parallel-netcdf
RUN wget http://cucis.ece.northwestern.edu/projects/PnetCDF/Release/parallel-netcdf-1.8.1.tar.gz && \
    tar -xzvf parallel-netcdf-1.8.1.tar.gz && \
    mkdir /parallel-netcdf && \
    cd parallel-netcdf-1.8.1 && \
    ./configure \
    --disable-debug \
    --prefix=$PREFIX && \
    make && \
    make check testing && \
    make install && \
    cd .. && \
    rm -rf *
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/parallel-netcdf/lib


#install PIO -- old version, newer requires CMAKE
ENV PREFIX /pio
ENV NETCDF_PATH=/netcdf4 \
    PNETCDF_PATH=/parallel-netcdf
RUN wget https://github.com/NCAR/ParallelIO/archive/pio1_7_2.tar.gz && \
    tar -xzvf pio1_7_2.tar.gz && \
    mkdir /pio && \
    cd ParallelIO-pio1_7_2/pio && \
    ./configure \
    --disable-debug \
    --prefix=$PREFIX && \
    make && \
    make install && \
    cd /Downloads && \
    rm -rf *
ENV PIO=/pio \
    NETCDF=/netcdf4 \
    PNETCDF=/parallel-netcdf

# Install metis
RUN wget http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz && \
    tar -xzvf metis-5.1.0.tar.gz &&\
    cd metis-5.1.0 && \
    make config && \
    make install && \
    cd .. && \
    rm -rf *


# why here
ENV PATH /usr/local/bin:$PATH
ENV LANG C.UTF-8


 
# python 2   
RUN pip install numpy && \
    pip install netCDF4 && \
    pip install GitPython  
    
# Python 3
RUN yum -y update \
    && yum -y install curl bzip2 \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local/ \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=3 \
    && conda update conda \
    && conda clean --all --yes \
    && rpm -e --nodeps curl bzip2 \
    && yum clean all

RUN RUN pip install numpy && \
    pip install netCDF4 && \
    pip install GitPython 

# ACME
WORKDIR /ACME
RUN mkdir scratch && \
  mkdir -p cime/utils/git && \
  wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh && \
  wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
  

RUN useradd --create-home -s /bin/bash user
WORKDIR /Develop