#!/usr/bin/env ruby
# encoding: utf-8

# Filter a list of words (infile) through a G2P, for e.g. Kaldi's data/local/dict/lexicon.txt.
# Run this in a shell WITHOUT "export LC_ALL=C".

# The g2p file may start with a Unicode Byte Order Marker (BOM) header, <feff>, ef bb bf,
# which if ignored prevents "a ɑ" from matching anything.
# Strip it manually, because for UTF-8 files the BOM is neither required nor recommended,
# http://stackoverflow.com/a/2223926/2097284.
g2p = "Swahili_ref_orthography_dict.txt" # http://isle.illinois.edu/sst/data/dict/Swahili/Swahili_ref_orthography_dict.txt
infile = "swahili-words.txt"

# English words polluting infile will g2p incorrectly because of missing graphemes,
# e.g. academy ɑ ɑ ɗ ɛ m j.
# European words with Ö ρ ć etc similarly lose graphemes and thus phonemes.
#
# Swahili's dict's lines have the form: g's, spaces or tabs, p.
# Each p might be several chars long.
# Parse "mb\tᵐb" into ["mb", "ᵐb "].
$g2p = File.readlines(g2p) .map {|l| l.chomp} .delete_if {|l| l.empty?} \
  .map {|l| [ l[/[^\s]*/], l[/[^\s]+$/]+' ' ] }

# todo: String.g2pify, return what would be printed.  Only the caller actually prints.
def g2pify(l)
  fWordPrinted = false
  until l.empty?
    if l[0] == ' ' || l[0] == "'" || l[0] == ','
      # This grapheme is non-spoken, so skip it.
      l = l[1 .. -1]
      next
    end
      
    # Find which graphemes in $g2p match the start of l.
    matches = $g2p.select {|g| (l =~ /#{g[0]}/) == 0 } .sort_by {|m| m[0].size}
    if matches.empty?
      # This grapheme is non-spoken, so skip it.
      l = l[1 .. -1]
      next
    end
    # This matched the longest prefix of l.
    mLongest = matches[-1]
    # Print the word (and a tab), only now that we know that it has phonemes to print as well.
    if !fWordPrinted
      fWordPrinted = true
      print "#{l}\t"
    end
    # Print one or more (phoneme, space) pairs.
    print mLongest[1]
    # Strip off what was matched.
    l = l[mLongest[0].size .. -1]
  end
  print "\n" if fWordPrinted
end

$in = File.readlines(infile).map {|l| l.chomp.downcase} \
  .delete_if {|l| l.empty?}
$in.each {|l| g2pify(l) }

# See also /r/lorelei/mturk/tur-phone-lm/a.rb.
