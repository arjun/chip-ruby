# !/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'affymetrix'

chp = CHP.new( :filename => "../data/NA06985_GW6_C.birdseed.chp", 
               :maxlines => 100,
               :verbosity => :normal)
chp.write_data_sets('out.csv')

# The file HG-Focus-2-121502.calvin.CHP contains:

# MAS5 Results
# 
# The analysis results from the MAS5 algorithm are stored in a file with a single group with a single data set. The data set header will contain a set of parameters to define the column labels. See the MAS5 Statistical Algorithm Description document on the Affymetrix web site for a description on each metric.
# 
# The data type identifier is set to: "affymetrix-expression-probeset-analysis"
# 
# The data group containing the analysis results is called "Expression Results". It contains a single data set, also called "Expression Results", containing the analysis results. The data set contains the following columns.
# Column Name Column Type
# Probe Set Name  Ascii
# Detection UByte (0 = present, 1 = marginal, 2 = absent, no call otherwise)
# Detection p-value Float
# Signal  Float
# Number of Pairs UShort
# Number of Pairs Used  UShort

# A second data group provides storage for the background zone information. This is the background value computed by the MAS5 algorithm on a per zone basis. The data set header will contain a set of parameters to define the column labels.
# 
# The data group name is called "Background Zone Data". It contains a single data set, also called "Background Zone Data", containing the background values for each zone. The data set contains the following columns.
# Column Name Column Type
# Center X  Float
# Center Y  Float
# Background  Float
# SmoothFactor  Float

# 
# chp2 = CHP.new( :filename => "../data/HG-Focus-2-121502.calvin.CHP",
#                 :maxlines => 10,
#                 :verbosity => :debug)

# todo: CEL files
# cel = CEL.new(:filename => "../data/Test3-1-121502.calvin.CEL"
#                :maxlines => 100)

