#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'affymetrix'

chp = CHP.new("../data/NA06985_GW6_C.birdseed.chp", 10)
# chp2 = CHP.new("../data/10K_1-calvin.CHP", 10)
