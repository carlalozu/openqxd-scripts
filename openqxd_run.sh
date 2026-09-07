
export OPENQXD_DIR="$SCRATCH/openQxD-devel"
export QUDA_BUILD_DIR="$SCRATCH/quda-build"
export OPENQXD_BUILD_DIR="$SCRATCH/openqxd-build"

bash build_openqxd.sh

# echo "Running check6 program"
# cd $OPENQXD_BUILD_DIR/devel/forces
# mpiexec -n 8 ./check6 -i check6.in -bc 3 -cs 1
# 
# echo "Running test3 test"
# cd $OPENQXD_BUILD_DIR/tests/update
# mpiexec -n 8 ./test3

echo "Running force tests"
cd $OPENQXD_BUILD_DIR/devel/forces
# mpiexec -n 8 ./test6
ctest -R 'test6'