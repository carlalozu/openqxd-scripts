
export OPENQXD_DIR="$SCRATCH/openQxD-devel"
export QUDA_BUILD_DIR="$SCRATCH/quda-build"
export QUDA="ON"

export CACHE_DIR=$SCRATCH/quda-build/cache
export QUDA_RESOURCE_PATH=$CACHE_DIR
export QUDA_PROFILE_OUTPUT_BASE=$CACHE_DIR

# rm -rf $CACHE_DIR
mkdir -p $CACHE_DIR

cd $SCRATCH

# Compile time parameters, change global.h
perl -i -pe "s/#define NPROC0 \\d+/#define NPROC0 1/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define NPROC1 \\d+/#define NPROC1 2/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define NPROC2 \\d+/#define NPROC2 2/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define NPROC3 \\d+/#define NPROC3 2/" $OPENQXD_DIR/include/global.h


perl -i -pe "s/#define L0 \\d+/#define L0 8/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define L1 \\d+/#define L1 8/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define L2 \\d+/#define L2 8/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define L3 \\d+/#define L3 8/" $OPENQXD_DIR/include/global.h


perl -i -pe "s/#define NPROC0_BLK \\d+/#define NPROC0_BLK 1/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define NPROC1_BLK \\d+/#define NPROC1_BLK 1/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define NPROC2_BLK \\d+/#define NPROC2_BLK 1/" $OPENQXD_DIR/include/global.h
perl -i -pe "s/#define NPROC3_BLK \\d+/#define NPROC3_BLK 1/" $OPENQXD_DIR/include/global.h


cmake -S openQxD-devel/ -B openqxd-build \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENQXD_ENABLE_QUDA=${QUDA} \
    -DOPENQXD_QUDA_BUILD=${QUDA_BUILD_DIR}
cmake --build openqxd-build -- -j8
