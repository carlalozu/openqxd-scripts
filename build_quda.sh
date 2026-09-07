# uenv start --view=modules prgenv-gnu/25.6:v1
# module load cuda/12.9.0 cray-mpich/8.1.32


export SCRIPTS_DIR=$SCRATCH/lattice-scripts/quda
export QUDA_DIR=$SCRATCH/quda

cd $SCRATCH

computer=daint
cp $SCRIPTS_DIR/CMakePresets.json $QUDA_DIR/CMakePresets.json
cmake -S quda/ -B quda-build --preset="$computer-quda"
cmake --build quda-build -- -j8

l0=16
l1=16
l2=16
l3=16

./quda-build/tests/plaq_test --tdim $l0 --xdim $l1 --ydim $l2 --zdim $l3 --prec double
./quda-build/tests/gauge_path_test --tdim $l0 --xdim $l1 --ydim $l2 --zdim $l3 --prec double


### TODO: caching parameters
export CACHE_DIR=$SCRATCH/quda-build/cache

# rm -rf $CACHE_DIR
mkdir -p $CACHE_DIR

export QUDA_RESOURCE_PATH=$CACHE_DIR
export QUDA_PROFILE_OUTPUT_BASE=$CACHE_DIR
