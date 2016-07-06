# Pseudo-Swahili recipe for Kaldi ASR

Uses almost no Swahili resources.
Audio FSTs are trained from Voxforge's English.

Usage:

```
git clone https://www.github.com/kaldi-asr/kaldi
cd kaldi/egs
git clone https://www.github.com/uiuc-sst/pseudo-swahili
cd pseudo-swahili/s5
ln -s ../../wsj/s5/steps steps
ln -s ../../wsj/s5/utils utils
./run.sh
```
