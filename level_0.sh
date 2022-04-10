#-> Install general usage dependencies
apt-get update
apt-get upgrade -y
apt-get install -y apt-file
apt-file update
apt-get install -y -qq --no-install-recommends \
    cmake \
    ffmpeg \
    g++ \
    git \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-thread-dev \
    libeigen3-dev \
    libglew-dev \
    libgtk2.0-dev \
    libpng-dev \
    libssl-dev \
    libswscale-dev \
    pkg-config \
    software-properties-common 

mkdir /dpds/
cd /dpds/
git clone https://github.com/stevenlovegrove/Pangolin.git Pangolin
git clone https://github.com/Itseez/opencv.git opencv
git clone https://github.com/UZ-SLAMLab/ORB_SLAM3.git ORB_SLAM3

mkdir /dpds/Pangolin/build/
cd /dpds/Pangolin/build/
cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CPP11_NO_BOOST=1 \
    -D CMAKE_INSTALL_PREFIX=/opt/pangolin/ \
../
make -j6
make install

mkdir /dpds/opencv/build/
cd /dpds/opencv/build/
cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D ENABLE_AVX=OFF \
    -D WITH_OPENCL=OFF \
    -D WITH_IPP=OFF \
    -D WITH_TBB=ON \
    -D BUILD_TBB=ON \
    -D WITH_EIGEN=ON \
    -D WITH_V4L=OFF \
    -D WITH_VTK=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
../
make -j6
make install
ldconfig

mkdir /dpds/ORB_SLAM3/Thirdparty/DBoW2/build/
cd /dpds/ORB_SLAM3/Thirdparty/DBoW2/build/
cmake \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_PREFIX_PATH=/opt/opencv/ \
../
make -j6

mkdir /dpds/ORB_SLAM3/Thirdparty/g2o/build/
cd /dpds/ORB_SLAM3/Thirdparty/g2o/build/
cmake \
    -D CMAKE_BUILD_TYPE=Release \
../
make -j6

mkdir /dpds/ORB_SLAM3/Thirdparty/Sophus/build/
cd /dpds/ORB_SLAM3/Thirdparty/Sophus/build/
cmake \
    -D CMAKE_BUILD_TYPE=Release \
../
make -j6

cd /dpds/ORB_SLAM3/Vocabulary/
tar -xf ORBvoc.txt.tar.gz

mkdir /dpds/ORB_SLAM3/build/
cd /dpds/ORB_SLAM3/build/
cmake \
    -D CMAKE_BUILD_TYPE=Release \
    -Wno-dev \
../
make -j6