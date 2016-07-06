# Pseudo-Swahili recipe for Kaldi ASR

Uses almost no Swahili resources.
Audio FSTs are trained from Voxforge's English.

### Usage:

To install the code:
```
git clone https://www.github.com/kaldi-asr/kaldi
cd kaldi/egs
git clone https://www.github.com/uiuc-sst/pseudo-swahili
cd pseudo-swahili/s5
ln -s ../../wsj/s5/steps steps
ln -s ../../wsj/s5/utils utils
```

To install the Voxforge data (this takes 45 minutes, and eats 25 GB of disk space):
```
./getdata.sh
```

To build and test the ASR:
```
./run.sh
```

### Prerequisites:

From a shell prompt, the commands `wget`, `gawk` and `flac` should work.  On Ubuntu, you might need to `sudo apt-get install flac`.

Install SRILM.  Follow the instructions at `http://www.speech.sri.com/projects/srilm/download.html`, get the file `srilm.tgz`, and then (from `s5`) run `../../../tools/install_srilm.sh`.
