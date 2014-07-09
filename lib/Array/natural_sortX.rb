# Array/natural_sortX.rb
# Array#natural_sort!

# 20140519
# 0.1.0

# Description: This will sort an array of strings 'naturally' in place.

# Usage:
# %w{1 2 10 11 12 20}.natural_sort!
# => [1 2 10 11 12 20]
# cf.
# %w{1 2 10 11 12 20}.sort
# => [1 10 11 12 2 20]

require 'String/natural_comparison'

class Array
  
  def natural_sort!
    sort! do |a,b|
      String.natcmp(a,b)
    end
  end
  alias_method :natsort!, :natural_sort!
  
end
