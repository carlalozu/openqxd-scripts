#!/bin/bash
#SBATCH --account=eurohack-course2026-cscs
#SBATCH --reservation=eurohack
#SBATCH --nodes=2
#SBATCH --gres=gpu:4
#SBATCH --time=20:00
#SBATCH --uenv=prgenv-gnu/26.3:v1
#SBATCH --view=modules

ml gcc cuda cray-mpich

export OPENQXD_DIR="$SCRATCH/openQxD-devel"
export QUDA_BUILD_DIR="$SCRATCH/quda-build"
export OPENQXD_BUILD_DIR="$SCRATCH/openqxd-build"

export CACHE_DIR=$SCRATCH/quda-build/cache
export QUDA_RESOURCE_PATH=$CACHE_DIR
export QUDA_PROFILE_OUTPUT_BASE=""

# rm -rf $CACHE_DIR
mkdir -p $CACHE_DIR

bash build_openqxd.sh

# echo "Running check6 program"
# cd $OPENQXD_BUILD_DIR/devel/forces
# mpiexec -n 8 ./check6 -i check6.in -bc 3 -cs 1

# echo "Running test3 test"
# cd $OPENQXD_BUILD_DIR/tests/update
# mpiexec -n 8 ./test3

echo "Running force tests"
cd $OPENQXD_BUILD_DIR/devel/forces

srun -n8 test6
