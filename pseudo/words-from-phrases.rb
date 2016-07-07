#!/usr/bin/env ruby
# encoding: utf-8

# Extract a list of bare words from swahili-phrases.txt.
# Run this in a shell WITHOUT "export LC_ALL=C".
# Output to swahili-words.txt.

$in = File.readlines("swahili-phrases.txt").map &:chomp

lines = $in.map {|l| l.gsub(' ', '\n').split('\n') } .flatten \
  .map {|l| l.gsub(/ +/, ' ').strip} \
  .delete_if {|l| l.empty? || l =~ /[^a-z]/}	# Lowercase, like swahili-phrases.txt.

puts lines.sort.uniq
exit 0
