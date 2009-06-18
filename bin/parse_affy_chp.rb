#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require "affymetrix"

# full .chp file is processed (and .csv output) in about 2mins on 2.4Ghz iMac with :verbosity => :quiet
chp = GenotypingCHP.new(:filename => "../data/NA06985_GW6_C.birdseed.chp", :verbosity => :quiet)
chp.print_header
chp.print_data_groups
chp.print_data_sets
chp.write_data_sets(:filename  => "../data/NA06985_GW6_C.birdseed.csv", :format  => "csv")

# The file HG-Focus-2-121502.calvin.CHP contains MAS5 Results
# To parse MAS5 ExpressionCHP files use this:
# chp = ExpressionCHP.new( :filename => "../data/HG-Focus-2-121502.calvin.CHP", :maxlines => 10, :verbosity => :normal)
