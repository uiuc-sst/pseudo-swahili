#!/usr/bin/env ruby
# encoding: utf-8

# Filter raw text from e.g. http://ifp-08.ifp.uiuc.edu/public/wikipedia/sw/
# Run this in a shell WITHOUT "export LC_ALL=C".
# Send it to swahili-phrases.txt,
# as uppercase just like /r/lorelei/kaldi/egs/voxforge.

# As input for the g2p, also include raw-placenames.txt, utterances including "dar es salaam" etc,
# to put those in the dictionary.

# todo: wget -r -N --no-parent http://ifp-08.ifp.uiuc.edu/public/wikipedia/sw/, cat .../*.txt > raw.txt.

# Convert digits and weird characters to spaces, because swahili-phrases.txt feeds pseudo-swahili.arpa.
# Downcase to simplify stripping of noise.
$in = (File.readlines("raw.txt") + File.readlines("raw-placenames.txt")) \
  .map {|l| l.chomp.downcase} \
  .delete_if {|l| l.empty?} \
  .map {|l| l.gsub /(?<=[0-9])[,\.](?=[0-9])/, ''}	# Strip comma or period between digits (1,000,000)
  .map {|l| l.gsub /<^sw /, ''}				# Strip some of wikipedia's boilerplate.
  .map {|l| l.gsub(/&nbsp;|&amp;|\\frac|\\left|\\right|absent_articles| – |, /, ' ')} \
  .map {|l| l.gsub(/[0-9\#_,:;=\*\/%–—†°²ː|'"“”„’ʻ`(){}\-\[\]^Ⅰ\&]+/, ' ')} \
  .map {|l| l.gsub /<[^>]+>/, ' '}			# Strip html, e.g. < ref name"Hartl_and_Jones">.

# todo: strip wikipedia's boilerplate, or rescrape pages that are more representative of spoken Swahili.

# Both l.downcase.tr('Æ-Ý','æ-ý') and force_encoding('UTF-8').downcase miss some accented letters.
# More complete might be https://github.com/blackwinter/unicode, Unicode::downcase('Æ-Ý').
# But it doesn't matter while words-from-phrases.rb filters out non-a-to-z words.
#
# Or should *this* script delete such words, and replace them with a line break?

# Split lines at sentence-ending punctuations.
lines = $in.map {|l| l.gsub(/[\.\!\?]+/, '\n').split('\n') } .flatten \
  .map {|l| l.gsub(/ +/, ' ') .sub(/^[^a-z][ ]?/, '') .strip} \
  .map {|l| l.force_encoding('UTF-8').downcase} \
  .delete_if {|l| l.empty? || l.size < 2}
# todo: delete lines >= 4 words, whose words are more than 50% English
# todo: delete and linebreak at sequences of English words that are 3 or longer

puts lines.sort.uniq
exit 0
