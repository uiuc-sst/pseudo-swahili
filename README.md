# Pseudo-Swahili ASR for Kaldi

Uses almost no Swahili resources.
Audio FSTs are trained from Voxforge's English.

### Prerequisites

- The shell commands `flac`, `gawk`, `swig`, and `wget`.  
On Ubuntu, you might need to `sudo apt install flac gawk swig wget`.

- The [Kaldi](http://kaldi-asr.org) toolkit for automatic speech recognition.  
To install it, `git clone https://www.github.com/kaldi-asr/kaldi`.

- The [SRI Language Modeling Toolkit](http://www.speech.sri.com/projects/srilm/).  
To add this to Kaldi, [download](http://www.speech.sri.com/projects/srilm/download.html) the file `srilm.tgz` into `kaldi/tools`, and then (from `kaldi/tools`) `./install_srilm.sh`.

- The [Sequitur](https://www-i6.informatik.rwth-aachen.de/web/Software/g2p.html) grapheme-to-phoneme converter.  
To add this to Kaldi, `cd kaldi/tools && extras/install_sequitur.sh`.  
(You might first need to `sudo pip install numpy` (for Python 2.7)).

### Usage

Add these pseudo-Swahili scripts to Kaldi.
```
cd kaldi/egs
git clone https://www.github.com/uiuc-sst/pseudo-swahili
cd pseudo-swahili/s5
ln -s ../../wsj/s5/steps steps
ln -s ../../wsj/s5/utils utils
```

Get the Voxforge corpus of spoken English (this takes 45 minutes, and uses 25 GB of disk space).  
`./getdata.sh`

Build the low-resource language model, vocabulary, etc. for Swahili.  
`cd pseudo-swahili/pseudo && ./a.sh`

Build and test the speech recognizer.  
`cd pseudo-swahili/s5 && ./run.sh`
