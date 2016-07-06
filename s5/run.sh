#!/bin/bash

# Copyright 2012 Vassil Panayotov
# Apache 2.0

# NOTE: You will want to download the data set first, before executing this script.
#       This can be done for example by:
#       1. Setting the DATA_ROOT variable to point to a directory with enough free
#          space (at least 20-25GB currently (Feb 2014))
#       2. Running "getdata.sh"

# The second part of this script comes mostly from egs/rm/s5/run.sh
# with some parameters changed

export LC_ALL=C

. ./path.sh || exit 1

# If you have cluster of machines running GridEngine you may want to
# change the train and decode commands in the file below
. ./cmd.sh || exit 1

# The number of parallel jobs for some parts of the recipe.
# Ensure you have enough RAM for this many jobs.
njobs=$((`nproc`-2))

dialects="((American)|(British)|(Australia)|(Zealand))"

# The number of randomly selected speakers to be put in the test set
nspk_test=20

# Test-time language model order.  Also the order for which to build lm.arpa.
lm_order=2

# Word position dependent phones?
# Camille tried "false", but that crashes downstream.
pos_dep_phones=true

# DATA_ROOT="/tmp/voxforge" is from ./path.sh.

# The directory below will be used to link to a subset of the user directories
# based on various criteria(currently just speaker's accent)
selected=${DATA_ROOT}/selected

pseudo=/r/lorelei/pseudo-swahili

# The user of this script could change some of the above parameters. Example:
# /bin/bash run.sh --pos-dep-phones false
. utils/parse_options.sh || exit 1

[[ $# -ge 1 ]] && { echo "Unexpected arguments"; exit 1; } 
#if false; then # fi	;;;;
#fi  # if false; then	;;;;

# Make ${selected} == /tmp/voxforge/selected,
# containing symlinks to utterances, e.g.
# /tmp/voxforge/extracted/ariyan-20120801-gra/ , containing wav/*.wav and
# transcript etc/PROMPTS, lines like: ariyan-20120801-gra/mfc/b0269 WHY NOT LIKE ANY RAILROAD STATION OR FERRY DEPOT
# transcript etc/prompts-original: b0269 Why not like any railroad station or ferry depot.
local/voxforge_select.sh --dialect $dialects \
  ${DATA_ROOT}/extracted ${selected} || exit 1

# Map anonymous speakers, /tmp/voxforge/selected/anonymous-yyyymmdd-abc, to unique IDs.
# Make data/local/anon.map, lines like: anonymous0042 /tmp/voxforge/selected/anonymous-20080425-atw
local/voxforge_map_anonymous.sh ${selected} || exit 1

# Make:
# data/local
# data/local/tmp 
# data/local/tmp/speakers_all.txt from /tmp/voxforge/selected, a list of utterers.
#	(But pseudo has no utterers.  Each utterance gets its own utterance-id.)
# data/local/tmp/speakers_test.txt (shuffle ...all.txt | head -$nspk_test)
# data/local/tmp/speakers_train.txt (the set difference)
#
# data/local/tmp/dir_test.txt has 20 lines: anonymous0232-20090406-ifh
# data/local/tmp/dir_train.txt has 4013 lines
#
# data/local/tmp/{test,train}{_wav.scp,_trans.txt,.utt2spk}.unsorted
#   test_wav.scp.unsorted has 274 lines: foo-jxh-a0077 /tmp/voxforge/selected/foo-jxh/wav/a0077.wav
#   test.utt2spk.unsorted has 274 lines: test-20100811-jxh-a0077 test
#   test_trans.txt.unsorted has 274    : test-20100811-jxh-a0077 IT IS THE FIRE PARTLY SHE SAID
# Skip audio lacking a transcript, and then sort, to make
# data/local/tmp/{test,train}{_wav.scp,_trans.txt,.utt2spk}
#
# data/local/tmp/{test,train}.spk2utt, from {test,train}_trans.txt
# (but why not instead utils/utt2spk_to_spk2utt.pl?)
local/voxforge_data_prep.sh --nspk_test ${nspk_test} ${selected} || exit 1

# Prepare ARPA LM and vocabulary using SRILM
# Reads data/local/tmp/corpus.txt, 18k lines of (uppercase) prose.
# INSTEAD of corpus.txt, /r/lorelei/pseudo-swahili/a.sh makes lm.arpa from raw.txt, raw-placenames.txt.
# So this next line is probably redundant.
local/voxforge_prepare_lm.sh --order ${lm_order} || exit 1
# Inject.
cp $pseudo/pseudo-swahili.arpa data/local/lm.arpa

# Prepare the lexicon and various phone lists.  Just for English, for data/train.  Probably not needed.
local/voxforge_prepare_dict.sh || exit 1

# Prepare the lexicon and various phone lists.  For pseudo-Swahili, this time.
# Collect phones from lexicon.txt.
echo "SIL" > data/local/dict/silence_phones.txt
echo "SIL" > data/local/dict/optional_silence.txt
touch data/local/dict/extra_questions.txt # Later scripts expect this empty file.
cp $pseudo/lexicon.txt data/local/dict/lexicon.txt
sed 's/[^\t]*\t//' data/local/dict/lexicon.txt | sed 's/ /\n/g' | sort -u | sed '/^$/d' | grep -v SIL > data/local/dict/nonsilence_phones.txt

# Prepare data/lang and data/local/lang directories
utils/prepare_lang.sh --position-dependent-phones $pos_dep_phones \
  data/local/dict '!SIL' data/local/lang data/lang || exit 1

# Prepare G.fst and data/{train,test} directories.  Actually, just data/train.
local/voxforge_format_data.sh || exit 1

# local/voxforge_format_data.sh uses these files, data/local/tmp/{test,train}{_wav.scp,_trans.txt,.utt2spk},
# and copies them to data/{train,test}.
#
# Collect wav's and transcriptions from ifp-53: ~/kaldi-trunk/egs/swahili/s5/asr_swahili/data/test126.
wavz=/tmp/pseudo-swahili/test126/wav5/a
trannz=/tmp/pseudo-swahili/test126/transcriptions-raw
echo "Normalizing test data from BABEL."
for f in $wavz/*.wav; do echo `basename "${f%.wav}"` "$f"; done | sort > data/test/wav.scp
for f in $trannz/*.txt; do basename "${f%.txt}"; done > /tmp/text-uttIDs
for f in $trannz/*.txt; do grep sta "$f" | sed 's/.sta. //';  done > /tmp/text-transcriptions
paste -d" " /tmp/text-uttIDs /tmp/text-transcriptions | sort > data/test/text
paste -d" " /tmp/text-uttIDs /tmp/text-uttIDs         | sort > data/test/utt2spk
utils/utt2spk_to_spk2utt.pl data/test/utt2spk                > data/test/spk2utt

echo "Making MFCCs."
# Store MFCC features in $mfccdir.  Do test before train because that's faster.
mfccdir=${DATA_ROOT}/mfcc
for x in test train; do 
 steps/make_mfcc.sh --cmd "$train_cmd" --nj $njobs \
   data/$x exp/make_mfcc/$x $mfccdir || exit 1;
 steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
done

# Train monophone models on a subset of the data
utils/subset_data_dir.sh data/train 1000 data/train.1k  || exit 1;
steps/train_mono.sh --nj $njobs --cmd "$train_cmd" data/train.1k data/lang exp/mono  || exit 1;

# Monophone decoding
utils/mkgraph.sh --mono data/lang_test exp/mono exp/mono/graph || exit 1
# note: local/decode.sh calls the command line once for each
# test, and afterwards averages the WERs into (in this case
# exp/mono/decode/
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
  exp/mono/graph data/test exp/mono/decode

# Get alignments from monophone system.
steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
  data/train data/lang exp/mono exp/mono_ali || exit 1;

# It got this far! ;;;;

# train tri1 [first triphone pass]
steps/train_deltas.sh --cmd "$train_cmd" \
  2000 11000 data/train data/lang exp/mono_ali exp/tri1 || exit 1;

# decode tri1
utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph || exit 1;
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
  exp/tri1/graph data/test exp/tri1/decode

#draw-tree data/lang/phones.txt exp/tri1/tree | dot -Tps -Gsize=8,10.5 | ps2pdf - tree.pdf

# align tri1
steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
  --use-graphs true data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

# train tri2a [delta+delta-deltas]
steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 \
  data/train data/lang exp/tri1_ali exp/tri2a || exit 1;

# decode tri2a
utils/mkgraph.sh data/lang_test exp/tri2a exp/tri2a/graph
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
  exp/tri2a/graph data/test exp/tri2a/decode

# train and decode tri2b [LDA+MLLT]
steps/train_lda_mllt.sh --cmd "$train_cmd" 2000 11000 \
  data/train data/lang exp/tri1_ali exp/tri2b || exit 1;
utils/mkgraph.sh data/lang_test exp/tri2b exp/tri2b/graph
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
  exp/tri2b/graph data/test exp/tri2b/decode

# Align all data with LDA+MLLT system (tri2b)
steps/align_si.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
   data/train data/lang exp/tri2b exp/tri2b_ali || exit 1;

#  Do MMI on top of LDA+MLLT.
steps/make_denlats.sh --nj $njobs --cmd "$train_cmd" \
  data/train data/lang exp/tri2b exp/tri2b_denlats || exit 1;
steps/train_mmi.sh data/train data/lang exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mmi || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \
   exp/tri2b/graph data/test exp/tri2b_mmi/decode_it4
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \
   exp/tri2b/graph data/test exp/tri2b_mmi/decode_it3

# Do the same with boosting.
steps/train_mmi.sh --boost 0.05 data/train data/lang \
   exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mmi_b0.05 || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \
   exp/tri2b/graph data/test exp/tri2b_mmi_b0.05/decode_it4 || exit 1;
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \
   exp/tri2b/graph data/test exp/tri2b_mmi_b0.05/decode_it3 || exit 1;

# Do MPE.
steps/train_mpe.sh data/train data/lang exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mpe || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \
   exp/tri2b/graph data/test exp/tri2b_mpe/decode_it4 || exit 1;
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \
   exp/tri2b/graph data/test exp/tri2b_mpe/decode_it3 || exit 1;


## Do LDA+MLLT+SAT, and decode.
steps/train_sat.sh 2000 11000 data/train data/lang exp/tri2b_ali exp/tri3b || exit 1;
utils/mkgraph.sh data/lang_test exp/tri3b exp/tri3b/graph || exit 1;
steps/decode_fmllr.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
  exp/tri3b/graph data/test exp/tri3b/decode || exit 1;


# Align all data with LDA+MLLT+SAT system (tri3b)
steps/align_fmllr.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
  data/train data/lang exp/tri3b exp/tri3b_ali || exit 1;

## MMI on top of tri3b (i.e. LDA+MLLT+SAT+MMI)
steps/make_denlats.sh --config conf/decode.config \
   --nj $njobs --cmd "$train_cmd" --transform-dir exp/tri3b_ali \
  data/train data/lang exp/tri3b exp/tri3b_denlats || exit 1;
steps/train_mmi.sh data/train data/lang exp/tri3b_ali exp/tri3b_denlats exp/tri3b_mmi || exit 1;

steps/decode_fmllr.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
  --alignment-model exp/tri3b/final.alimdl --adapt-model exp/tri3b/final.mdl \
   exp/tri3b/graph data/test exp/tri3b_mmi/decode || exit 1;

# Do a decoding that uses the exp/tri3b/decode directory to get transforms from.
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
  --transform-dir exp/tri3b/decode  exp/tri3b/graph data/test exp/tri3b_mmi/decode2 || exit 1;


#first, train UBM for fMMI experiments.
steps/train_diag_ubm.sh --silence-weight 0.5 --nj $njobs --cmd "$train_cmd" \
  250 data/train data/lang exp/tri3b_ali exp/dubm3b

# Next, various fMMI+MMI configurations.
steps/train_mmi_fmmi.sh --learning-rate 0.0025 \
  --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \
  exp/tri3b_fmmi_b || exit 1;

for iter in 3 4 5 6 7 8; do
 steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \
   --transform-dir exp/tri3b/decode  exp/tri3b/graph data/test exp/tri3b_fmmi_b/decode_it$iter &
done

steps/train_mmi_fmmi.sh --learning-rate 0.001 \
  --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \
  exp/tri3b_fmmi_c || exit 1;

for iter in 3 4 5 6 7 8; do
 steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \
   --transform-dir exp/tri3b/decode  exp/tri3b/graph data/test exp/tri3b_fmmi_c/decode_it$iter &
done

# for indirect one, use twice the learning rate.
steps/train_mmi_fmmi_indirect.sh --learning-rate 0.002 --schedule "fmmi fmmi fmmi fmmi mmi mmi mmi mmi" \
  --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \
  exp/tri3b_fmmi_d || exit 1;

for iter in 3 4 5 6 7 8; do
 steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \
   --transform-dir exp/tri3b/decode  exp/tri3b/graph data/test exp/tri3b_fmmi_d/decode_it$iter &
done

# This takes >24 hours, much longer than all of the rest of run.sh.
# In steps/train_sgmm2.sh, sgmm2-latgen-faster.
# Even with bigger $max_mem in egs/wsj/s5/steps/make_denlats_sgmm2.sh and bigger $njobs in run.sh.
#	local/run_sgmm2.sh --nj $njobs
