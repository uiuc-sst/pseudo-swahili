# Pseudo-Swahili recipe for Kaldi ASR

Uses almost no Swahili resources.
Audio FSTs are trained from Voxforge's English.

### Prerequisites

- The shell commands `wget`, `gawk`, `swig`, and `flac`.

On Ubuntu, you might need to `sudo apt-get install wget gawk swig flac`.

- The [Kaldi](http://kaldi-asr.org) toolkit for automatic speech recognition.

To install it, `git clone https://www.github.com/kaldi-asr/kaldi`.

- The [SRI Language Modeling Toolkit](http://www.speech.sri.com/projects/srilm/).

To add this to Kaldi, follow the [instructions](http://www.speech.sri.com/projects/srilm/download.html), download the file `srilm.tgz` into `kaldi/tools`, and then (from `kaldi/tools`) run `./install_srilm.sh`.

- The [Sequitur](https://www-i6.informatik.rwth-aachen.de/web/Software/g2p.html) grapheme-to-phoneme converter.

To add this to Kaldi, `cd kaldi/tools; extras/install_sequitur.sh`.

### Usage

To add these pseudo-Swahili scripts to Kaldi:
```
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

