require 'String/natural_comparison'

class Array
  
  def natural_sort!
    sort! do |a,b|
      String.natcmp(a,b)
    end
  end
  alias_method :natsort!, :natural_sort!
  
end

if __FILE__ == $0
  def success
    print '.'
  end

  def failure
    print'x'
  end
  
  ['abc1', 'abc12', 'abc123', 'abc2', 'abc23', 'abc234'].natsort == ['abc1', 'abc2', 'abc12', 'abc23', 'abc123', 'abc234'] ? success : failure
end
