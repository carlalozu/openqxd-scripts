# uenv start --view=modules prgenv-gnu/26.3:v1
# module load cuda cray-mpich


export SCRIPTS_DIR=$SCRATCH/openqxd-scripts
export QUDA_DIR=$SCRATCH/quda

cd $SCRATCH

# rm -rf quda-build

computer=daint
cp $SCRIPTS_DIR/CMakePresets.json $QUDA_DIR/CMakePresets.json
cmake -S quda/ -B quda-build --preset="$computer-quda"
cmake --build quda-build -- -j16
