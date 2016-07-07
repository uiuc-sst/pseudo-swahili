./a.sh makes:

pseudo-swahili.arpa
lexicon.txt
    It's lowercase, from make-pronundict.rb.
    What it replaces, data/local/dict/lexicon.txt, is uppercase, both word and phonemes.
    But the g2p Swahili_ref_orthography_dict.txt is inherently lowercase.
    So all the replacements should be lowercase too.
oovs.txt
lang-slash-G.fst
data-lang-words.txt
