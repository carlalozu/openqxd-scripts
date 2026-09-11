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
export QUDA="ON"

export CACHE_DIR=$SCRATCH/quda-build/cache
export QUDA_RESOURCE_PATH=$CACHE_DIR
export QUDA_PROFILE_OUTPUT_BASE=""

# rm -rf $CACHE_DIR
mkdir -p $CACHE_DIR


# ---- scaling test setup --------------------------------------------------
# Each entry: "L0 L1 L2 L3" (local lattice per rank). openQxD needs L_i even, >= 4.
CONFIGS=(
    "8  8  8  8"
    "8  12 12 12"
    "16 8  8  8"
    "16 16 16 16"
    "32 16 16 16"
    "32 32 32 32"
)
NPROC=(1 2 2 2)
NRANKS=8

RESULTS_DIR="$SCRATCH/scaling_check6_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"
GLOBAL_H="$OPENQXD_DIR/include/global.h"

for i in 0 1 2 3; do
    perl -i -pe "s/#define NPROC${i} \\d+/#define NPROC${i} ${NPROC[$i]}/" $GLOBAL_H
    perl -i -pe "s/#define NPROC${i}_BLK \\d+/#define NPROC${i}_BLK 1/" $GLOBAL_H
done

cd $SCRATCH

for idx in "${!CONFIGS[@]}"; do
    read -r L0 L1 L2 L3 <<< "${CONFIGS[$idx]}"
    L=($L0 $L1 $L2 $L3)
    TAG="L${L0}x${L1}x${L2}x${L3}"

    echo "=========================================================="
    echo " Config $idx: local ${TAG}"
    echo " global lattice: $((L0*NPROC[0])) x $((L1*NPROC[1])) x $((L2*NPROC[2])) x $((L3*NPROC[3])),  ${NRANKS} GPUs"
    echo "=========================================================="

    for i in 0 1 2 3; do
        perl -i -pe "s/#define L${i} \\d+/#define L${i} ${L[$i]}/" $GLOBAL_H
    done

    cmake -S openQxD-devel/ -B openqxd-build \
        -DCMAKE_BUILD_TYPE=Release \
        -DOPENQXD_ENABLE_QUDA=${QUDA} \
        -DOPENQXD_QUDA_BUILD=${QUDA_BUILD_DIR}
    cmake --build openqxd-build -- -j8 || { echo "Build failed for $TAG"; continue; }

    RUN_DIR="$RESULTS_DIR/${idx}_${TAG}"
    mkdir -p "$RUN_DIR"

    cd $OPENQXD_BUILD_DIR/devel/forces
    rm -rf check6 *.log
    mkdir -p check6

    echo "Running force tests ($TAG)"
    srun -n${NRANKS} test6
    srun -n${NRANKS} check6 -i check6.in -bc 3 -cs 1

    echo "$idx $TAG  test6: $((t1-t0)) s  check6: $((t2-t1)) s" | tee -a "$RESULTS_DIR/timings.txt"

    cp -r *.log check6 "$RUN_DIR/" 2>/dev/null
    cp $GLOBAL_H "$RUN_DIR/global.h"
    cd $SCRATCH
done