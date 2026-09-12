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
    "16 8  8  8"
    "24 12 12 12"
    "32 16 16 16"
    "48 24 24 24"
    "64 32 32 32"
)
NPROC=(1 2 2 2)
NRANKS=8

RESULTS_DIR="$SCRATCH/scaling_check6_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"
FORCE1_CSV="$RESULTS_DIR/force1_breakdown.csv"
echo "idx,tag,global_lattice,nranks,test6_global_ms,section,calls,self_ms,incl_ms,ms_per_call,pct_global" > "$FORCE1_CSV"
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
    GLAT="$((L0*NPROC[0]))x$((L1*NPROC[1]))x$((L2*NPROC[2]))x$((L3*NPROC[3]))"

    echo "=========================================================="
    echo " Config $idx: local ${TAG}"
    echo " global lattice: ${GLAT},  ${NRANKS} GPUs"
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
    rm -f *.log

    echo "Running force tests ($TAG)"
    srun -n${NRANKS} ./test6

    # Timing comes from the openQxD profiler table at the end of test6.log
    # (GLOBAL row: module section calls self(ms) incl(ms) ms/call % global)
    T6_MS=$(awk '$1=="GLOBAL"{t=$4} END{if(t!="")print t; else print "NA"}' test6.log)
    echo "$idx $TAG  test6 GLOBAL: ${T6_MS} ms" | tee -a "$RESULTS_DIR/timings.txt"

    # Per-solver force1 breakdown from the same table, one row per solver,
    # appended so every config ends up in the same file.
    awk -v idx="$idx" -v tag="$TAG" -v glat="$GLAT" -v nr="$NRANKS" -v tot="$T6_MS" '
        /^-+$/        { cur=""; next }
        {
            mod = substr($0,1,11); gsub(/ /,"",mod)
            if (mod != "") cur = mod
            if (cur != "force1") next
            if (split(substr($0,12), f, " ") < 6) next
            printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", \
                   idx, tag, glat, nr, tot, f[1], f[2], f[3], f[4], f[5], f[6]
        }' test6.log >> "$FORCE1_CSV"

    cp *.log "$RUN_DIR/" 2>/dev/null
    cp $GLOBAL_H "$RUN_DIR/global.h"
    cd $SCRATCH
done