#!/bin/bash
# set -x

FLINK_VERSION=$FLINK_VERSION
occlum_glibc=/opt/occlum/glibc/lib/
init_instance() {
    # Remove older instance
    rm -rf flink && mkdir flink
    cd flink
    # Init Occlum instance
    occlum init
    new_json="$(jq '.resource_limits.user_space_size = "7000MB" |
                .resource_limits.kernel_space_heap_size="64MB" |
                .resource_limits.max_num_of_threads = 72 |
                .process.default_heap_size = "128MB" |
                .process.default_mmap_size = "6600MB" |
                .entry_points = [ "/usr/lib/jvm/java-11-openjdk-amd64/bin" ] |
                .env.default = [ "LD_LIBRARY_PATH=/usr/lib/jvm/java-11-openjdk-amd64/lib/server:/usr/lib/jvm/java-11-openjdk-amd64/lib:/usr/lib/jvm/java-11-openjdk-amd64/../lib:/lib:/opt/occlum/glibc/lib/", "OMP_NUM_THREADS=1", "KMP_AFFINITY=verbose,granularity=fine,compact,1,0", "KMP_BLOCKTIME=20" ]' Occlum.json)" && \
    echo "${new_json}" > Occlum.json
   }

build_flink() {
    # Copy JVM and class file into Occlum instance and build
    mkdir -p image/usr/lib/jvm
    cp -r /usr/lib/jvm/java-11-openjdk-amd64 image/usr/lib/jvm
    cp /lib/x86_64-linux-gnu/libz.so.1 image/lib
    cp $occlum_glibc/libdl.so.2 image/$occlum_glibc
    cp $occlum_glibc/librt.so.1 image/$occlum_glibc
    cp $occlum_glibc/libm.so.6 image/$occlum_glibc
    cp $occlum_glibc/libnss_files.so.2 image/$occlum_glibc
    cp -rf ../flink-${FLINK_VERSION}/* image/bin/
    cp -rf ../flink-${FLINK_VERSION}/conf image/opt/
    cp -rf /etc/java-11-openjdk image/etc/
    cp -rf ../hosts image/etc/
    # build occlum
    occlum build
}

#Build the flink occlum instance
init_instance
build_flink
