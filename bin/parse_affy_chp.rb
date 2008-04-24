# !/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require "affymetrix"

chp = GenotypingCHP.new(:filename => "../data/NA06985_GW6_C.birdseed.chp", :maxlines => 100, :verbosity => :normal)
# chp.write_data_sets(:outfilename  => "out.yaml", :format  => 'yaml')

# The file HG-Focus-2-121502.calvin.CHP contains MAS5 Results
chp2 = ExpressionCHP.new( :filename => "../data/HG-Focus-2-121502.calvin.CHP", :maxlines => 10, :verbosity => :normal)

# todo
# cel = CEL.new(:filename => "../data/Test3-1-121502.calvin.CEL", :maxlines => 100, :verbosity  => :normal)

