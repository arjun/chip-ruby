# !/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require "affymetrix"

# chp = GenotypingCHP.new(:filename => "../data/NA06985_GW6_C.birdseed.chp", :maxlines => 100, :verbosity => :normal)
# The file HG-Focus-2-121502.calvin.CHP contains MAS5 Results
chp = ExpressionCHP.new( :filename => "../data/HG-Focus-2-121502.calvin.CHP", :maxlines => 10, :verbosity => :normal)
chp.print_header
chp.print_data_groups
chp.print_data_sets
chp.write_data_sets(:filename  => "out.csv", :format  => "csv")



# todo
# cel = CEL.new(:filename => "../data/Test3-1-121502.calvin.CEL", :maxlines => 100, :verbosity  => :normal)

