export KALDI_ROOT=$PWD/../../..
export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/onlinebin/:$KALDI_ROOT/src/lmbin/:$PWD:$PATH

export DATA_ROOT="/tmp/voxforge" # e.g., /media/secondary/voxforge
if [ -z $DATA_ROOT ]; then
  echo "In s5/path.sh, point DATA_ROOT to the directory that will hold VoxForge's data."
  exit 1
fi

# Make sure that MITLM shared libs are found by the dynamic linker/loader
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/tools/mitlm-svn/lib

source $KALDI_ROOT/tools/env.sh

# Needed for "correct" sorting
export LC_ALL=C
