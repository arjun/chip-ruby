# !/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'affymetrix'

chp = CHP.new( :filename => "../data/NA06985_GW6_C.birdseed.chp", 
               :maxlines => 100,
               :verbosity => :normal)
chp.write_data_sets('out.csv')

# todo: other CHP files
# chp2 = CHP.new("../data/HG-Focus-2-121502.calvin.CHP", 10)

# todo: CEL files
# cel = CEL.new("../data/Test3-1-121502.calvin.CEL", 10)

