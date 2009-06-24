#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require "affymetrix"

infile = ARGV[0]

# full .chp file is processed (and .csv output) in about 2mins on 2.4Ghz iMac with :verbosity => :quiet
chp = GenotypingCHP.new(:filename => infile, :verbosity => :quiet, :maxlines => 1000000)
# chp.print_header
# chp.print_data_groups
# chp.print_data_sets
chp.write_data_sets(:filename  => infile + '.csv', :format  => "csv")
