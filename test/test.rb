
#
# Testing
#
# Warning: under construction!
require "test/unit"

require "affymetrix"

class Silly < Test::Unit::TestCase
  def setup
    @chp = CHP.new( :filename => "../data/NA06985_GW6_C.birdseed.chp",
                   :maxlines => 100,
                   :verbosity => :quiet)
  end

  def test_silly_1
    assert_equal(@chp.filename, "../data/NA06985_GW6_C.birdseed.chp")
  end
end