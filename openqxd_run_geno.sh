export OPENQXD_DIR="$SCRATCH/openQxD-devel"
export QUDA_BUILD_DIR="$SCRATCH/quda-build"
export OPENQXD_BUILD_DIR="$SCRATCH/openqxd-build"

export CACHE_DIR=$SCRATCH/quda-build/cache
export QUDA_RESOURCE_PATH=$CACHE_DIR
export QUDA_PROFILE_OUTPUT_BASE="quda"

# rm -rf $CACHE_DIR
mkdir -p $CACHE_DIR

bash build_openqxd.sh

echo "Running force tests"
cd $OPENQXD_BUILD_DIR/devel/forces
mpiexec -n 8 ./check6 -i check6.in -bc 3 -cs 1
mpiexec -n 8 ./check9 -i check9.in -bc 3 -cs 1
mpiexec -n 8 ./check10 -i check10.in -bc 3 -cs 1


echo "Running quda tests"
cd $OPENQXD_BUILD_DIR/devel/quda
mpiexec -n 8 ./check_mscg
mpiexec -n 8 ./check_operators
