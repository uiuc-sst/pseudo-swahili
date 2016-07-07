#!/bin/bash
#
# Make lexicon.txt, pseudo-swahili.arpa, oovs.txt, lang-slash-G.fst
# from raw.txt, raw-placenames.txt.

# Reads raw.txt, raw-placenames.txt.
./tidy-wikipedia.rb > swahili-phrases.txt

# Reads swahili-phrases.txt.
#
# "| spell > swahili-words.txt" would keep only non-English words as possible Swahili,
# but would also corrupt the language model,
# because phrases would then include OOV words.
./words-from-phrases.rb > swahili-words.txt

# Convert swahili-words.txt to format of data/lang/words.txt.
#   Prepend <eps> (and <UNK>?) and !SIL; append \#0 and <s> and </s>.
#   To each line append space and line number.
echo "<eps> !SIL" `cat swahili-words.txt` "#0 <s> </s>" | tr \  '\n' | awk '{printf("%s %d\n", $0, NR-1)}' > data-lang-words.txt

# Reads swahili-words.txt, Swahili_ref_orthography_dict.txt
./make-pronundict.rb | (export LC_ALL=C; sort -u > lexicon.txt)
echo -e '!SIL\tSIL' >> lexicon.txt

# From /r/lorelei/kaldi/egs/camille/s5/local/prepare_lm.sh
. /r/lorelei/kaldi/egs/camille/s5/path.sh || die "path.sh expected"
. /r/lorelei/kaldi/tools/env.sh || die "tools/env.sh expected for SRILM"
# export SRILM=/r/lorelei/kaldi/tools/srilm
# export PATH=${PATH}:${SRILM}/bin:${SRILM}/bin/i686-m64
export LC_ALL=C # needed?
# /r/lorelei/kaldi/tools/srilm/bin/i686-m64/ngram-count
# -unk -map-unk "<UNK>"
ngram-count -text swahili-phrases.txt -order 3 -lm pseudo-swahili.arpa
	# Tell ngram-count about eps or SIL to avoid this:?
	#   warning: discount coeff 1 is out of range: 0
/r/lorelei/kaldi/egs/camille/s5/utils/find_arpa_oovs.pl data-lang-words.txt < pseudo-swahili.arpa | sort > oovs.txt
cat pseudo-swahili.arpa |
    grep -v '<s> <s>' |
    grep -v '</s> <s>' |
    grep -v '</s> </s>' |
    /r/lorelei/kaldi/src/bin/arpa2fst - | fstprint |
    /r/lorelei/kaldi/egs/camille/s5/utils/remove_oovs.pl oovs.txt |
    /r/lorelei/kaldi/egs/camille/s5/utils/eps2disambig.pl |
    /r/lorelei/kaldi/egs/camille/s5/utils/s2eps.pl |
    fstcompile --isymbols=data-lang-words.txt --osymbols=data-lang-words.txt --keep_isymbols=false --keep_osymbols=false |
    fstrmepsilon | fstarcsort --sort_type=ilabel > lang-slash-G.fst
