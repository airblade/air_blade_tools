module AirBlade
  module Formatting
    # TODO:
    #   - define sig_figs and decimal_places on Numeric (or whatever superclass is)
    def number_to_precise_size(size, precision = 1, use_significant_figures = true)
      '1 Byte'
    end

    def decimal_places(number, precision)
      number = Kernel.Float number
      "%.#{precision}f" % number
    end

    def sig_figs(number, precision)
      number = Kernel.Float(number).to_s
      output = ''
      count = 0     # number of significant figures we have seen
      msf = number.index /[1-9]/    # index of most significant figure, i.e. leftmost non-zero figure
      seen_decimal_point = false
      number.split(//).each_with_index do |digit, index|
        if index < msf
          output << digit
        elsif index == msf
          output << digit
          count += 1
        else
          if digit == '.'
            seen_decimal_point = true
            if count < precision
              output << digit
            else
              break
            end
          else
            if count < precision
              output << digit
              count += 1
            else
              if seen_decimal_point
                break
              else
                output << '0'
              end
            end
          end
        end
      end
      # Add on trailing zeros if necessary
      if (diff = precision - output[msf..-1].count('0-9')) > 0
        output << '0' * diff
      end

      # At this point output is rounded down.  We now round up
      # if necessary, using symmetric arithmetic rounding
      # (a.k.a. round-half-up).

      # Find least significant figure (at given precision) in original number.
      lsf = msf + precision - 1
      lsf += 1 if number[msf..precision] =~ /[.]/
      # Consider following digit.
      next_digit = number[lsf + 1, 1]
      if next_digit.to_i >= 5
        # Increment lsf in output
        lsf_output = (output.length > lsf) ? lsf : (output.length - 1)
        digit = output[lsf_output, 1]
        # TODO: walk backwards through string when digit is 9
        output[lsf_output] = digit.to_i.succ.to_s
      end

      output
    end

  end
end
