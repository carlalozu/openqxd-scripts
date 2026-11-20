#!/bin/bash
# Configure and build openQCD with the CMake presets in $OPENQCD_DIR
# (CMakePresets.json, and CMakeUserPresets.json for the paths on this
# machine), and optionally run the unit tests (tests/) with ctest.
#
# Usage: bash build_openqcd.sh [--test] [--profile] [--clean] [preset ...]
#                              [suite/name ...]
#   --test     run ctest after the build (the offload preset also runs
#              tests/openmp_target on the GPU, which the GitHub runners do not have)
#   --profile  also build the profiling programs (target openqcd_profile,
#              executables in build/<preset>/profile/<suite>/)
#   --clean    delete the build tree first
#   presets    default: gcc-geno clang-geno offload-geno quda-geno
#              the geno presets enable OPENQCD_ENABLE_AVX (except offload-geno)
#              cmake --list-presets=all (in $OPENQCD_DIR) lists them all
#   suite/name build only these profiling programs (profile/<suite>/<name>.c,
#              e.g. forces/time_force0) instead of the preset's targets;
#              implies --profile. With --test the tests are built and run too
#
# The lattice and process grid are those in include/global.h. Build trees go
# to $OPENQCD_DIR/build/<preset> and logs to $OPENQCD_DIR/build/<preset>.log.

OPENQCD_DIR=${OPENQCD_DIR:-$SCRATCH/openQCD-2.4}
JOBS=${JOBS:-$(nproc)}
CUDA_VISIBLE_DEVICES=$((OMPI_COMM_WORLD_LOCAL_RANK))

test=0
profile=0
clean=0
presets=()
programs=()
for arg in "$@"; do
    case $arg in
    --test)    test=1 ;;
    --profile) profile=1 ;;
    --clean)   clean=1 ;;
    -*)        sed -n '2,21s/^# \{0,1\}//p' "$0"; exit 1 ;;
    */*)       programs+=("profile_${arg%/*}_${arg##*/}") ;;
    *)         presets+=("$arg") ;;
    esac
done
[ ${#presets[@]} -eq 0 ] && presets=(gcc-geno clang-geno offload-geno quda-geno)
if [ ${#programs[@]} -gt 0 ]; then
    profile=1
elif [ $profile = 1 ]; then
    programs=(openqcd_profile)
fi

cd "$OPENQCD_DIR" || exit 1

run_preset() {
    preset=$1
    [ $clean = 1 ] && rm -rf "build/$preset"
    cmake --preset "$preset" &&
    # Skip the preset's own targets (the tests) when only specific profiling
    # programs were asked for and the tests are not run
    if [ $test = 1 ] || [ $profile = 0 ] || [ "${programs[*]}" = openqcd_profile ]; then
        cmake --build --preset "$preset" -j "$JOBS"
    fi &&
    if [ $profile = 1 ]; then
        cmake --build --preset "$preset" -j "$JOBS" --target "${programs[@]}"
    fi &&
    if [ $test = 1 ]; then ctest --preset "$preset"; fi
}

mkdir -p build
status=0
summary=""
for preset in "${presets[@]}"; do
    echo "===== $preset"
    log=$OPENQCD_DIR/build/$preset.log
    if run_preset "$preset" > "$log" 2>&1; then
        result=passed
    else
        result=FAILED
        status=1
    fi
    if [ $test = 1 ]; then
        grep -E "tests passed|tests failed|\*\*\*Failed|Error" "$log" | tail -20
    elif [ $result = FAILED ]; then
        tail -20 "$log"
    fi
    summary+="$(printf '%-14s %s (%s)' "$preset" $result "$log")"$'\n'
done

echo
echo "===== summary"
printf '%s' "$summary"
exit $status
