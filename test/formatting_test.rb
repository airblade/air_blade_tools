require 'test/unit'
require File.join(File.dirname(__FILE__), '..', 'lib', 'air_blade', 'formatting')
include AirBlade::Formatting

class FormattingTest < Test::Unit::TestCase

  def test_decimal_places
    assert_equal '0', decimal_places(0, 0)
    assert_equal '0.0', decimal_places(0, 1)
    assert_equal '322', decimal_places(321.9, 0)
    assert_equal '321.9', decimal_places(321.9, 1)
    assert_equal '321.90', decimal_places(321.9, 2)
    assert_equal '3', decimal_places(3.14159, 0)
    assert_equal '3.1', decimal_places(3.14159, 1)
    assert_equal '3.14', decimal_places(3.14159, 2)
    assert_equal '3.142', decimal_places(3.14159, 3)
    assert_equal '3.1416', decimal_places(3.14159, 4)
    assert_equal '3.14159', decimal_places(3.14159, 5)
  end

  def test_significant_figures
    assert_equal '10', sig_figs(12, 0)
    assert_equal '10', sig_figs(12, 1)
    assert_equal '12', sig_figs(12, 2)
    assert_equal '12.0', sig_figs(12, 3)
    assert_equal '12.00', sig_figs(12, 4)

    assert_equal '0.1', sig_figs(0.1, 0)
    assert_equal '0.1', sig_figs(0.1, 1)
    assert_equal '0.10', sig_figs(0.1, 2)
    assert_equal '0.100', sig_figs(0.1, 3)
    
    # Rounding
    assert_equal '3', sig_figs(3.14159, 1)
    assert_equal '3.1', sig_figs(3.14159, 2)
    assert_equal '3.14', sig_figs(3.14159, 3)
    assert_equal '3.142', sig_figs(3.14159, 4)
    assert_equal '3.1416', sig_figs(3.14159, 5)
    assert_equal '3.14159', sig_figs(3.14159, 6)

    assert_equal '20', sig_figs(15, 1)
    assert_equal '250', sig_figs(245, 2)
    assert_equal '245', sig_figs(245, 3)

    assert_equal '200', sig_figs(159, 1)
    assert_equal '160', sig_figs(159, 2)
    assert_equal '159', sig_figs(159, 3)
    assert_equal '159.0', sig_figs(159, 4)

    assert_equal '100', sig_figs(109, 1)
    assert_equal '110', sig_figs(109, 2)
    assert_equal '109', sig_figs(109, 3)
    assert_equal '109.0', sig_figs(109, 4)

    assert_equal '10', sig_figs(9.99, 1)
    assert_equal '10', sig_figs(9.99, 2)
    assert_equal '9.99', sig_figs(9.99, 3)
    assert_equal '9.990', sig_figs(9.99, 4)
  end
=begin
  def test_sig_figs_no_rounding
    assert_equal '1 Byte', number_to_human_size_scientifically(1)
    assert_equal '10 Bytes', number_to_human_size_scientifically(10)
    assert_equal '40 Bytes', number_to_human_size_scientifically(42)
    assert_equal '42 Bytes', number_to_human_size_scientifically(42, 2)
    assert_equal '42.00 Bytes', number_to_human_size_scientifically(42, 4)
  end
=end
end
