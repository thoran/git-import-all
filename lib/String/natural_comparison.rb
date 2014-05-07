# String#natural_comparison

# 20090729
# 0.0.1

# Description: I created this for svnimportall 0.7.7 because I wanted a 'nicer' version.  

class String
  
  class << self
    
    def natural_comparison(s1, s2, case_insensitive = nil)
      s1, s2 = (case_insensitive ? s1.downcase : s1), (case_insensitive ? s2.downcase : s2)
      m1, m2 = s1.match(/\d+/), s2.match(/\d+/)
      if m1 == nil || m2 == nil # then compare as per normal since one or more of the strings doesn't have numbers.  
        s1 <=> s2
      elsif m1.pre_match == m2.pre_match # then compare the remainder of the string, since the pre_matches are the same.  
        if m1[0] == m2[0]
          natcmp(m1.post_match, m2.post_match)
        else
          m1[0].to_i <=> m2[0].to_i
        end
      else # compare the pre_matches, since even though there are numbers the pre_matches are different anyway.  
        m1.pre_match <=> m2.pre_match
      end
    end
    
    alias_method :natcmp, :natural_comparison
    
  end # class << self
  
  def natural_comparison(s, case_insensitive = nil)
    String.natcmp(self, s, case_insensitive)
  end
  alias_method :natcmp, :natural_comparison
  
end

if __FILE__ == $0
  def success
    print '.'
  end

  def failure
    print'x'
  end
  
  String.natcmp('abc', 'abc') == 0 ? success : failure
  String.natcmp('abb', 'abc') == -1 ? success : failure
  String.natcmp('abc', 'abb') == 1 ? success : failure
  
  String.natcmp('abc123', 'abc123') == 0 ? success : failure
  String.natcmp('abb123', 'abc123') == -1 ? success : failure
  String.natcmp('abc123', 'abb123') == 1 ? success : failure
  String.natcmp('abc123', 'abc124') == -1 ? success : failure
  String.natcmp('abc124', 'abc123') == 1 ? success : failure
  
  String.natcmp('abc123a', 'abc123a') == 0 ? success : failure
  String.natcmp('abc123a', 'abc123b') == -1 ? success : failure
  String.natcmp('abc123b', 'abc123a') == 1 ? success : failure
  
  String.natcmp('abc123a1', 'abc123a1') == 0 ? success : failure
  String.natcmp('abc123a1', 'abc123a2') == -1 ? success : failure
  String.natcmp('abc123a2', 'abc123a1') == 1 ? success : failure
  
  'abc'.natcmp('abc') == 0 ? success : failure
  'abb'.natcmp('abc') == -1 ? success : failure
  'abc'.natcmp('abb') == 1 ? success : failure
  
  'abc123'.natcmp('abc123') == 0 ? success : failure
  'abb123'.natcmp('abc123') == -1 ? success : failure
  'abc123'.natcmp('abb123') == 1 ? success : failure
  'abc123'.natcmp('abc124') == -1 ? success : failure
  'abc124'.natcmp('abc123') == 1 ? success : failure
  
  'abc123a'.natcmp('abc123a') == 0 ? success : failure
  'abc123a'.natcmp('abc123b') == -1 ? success : failure
  'abc123b'.natcmp('abc123a') == 1 ? success : failure
  
  'abc123a1'.natcmp('abc123a1') == 0 ? success : failure
  'abc123a1'.natcmp('abc123a2') == -1 ? success : failure
  'abc123a2'.natcmp('abc123a1') == 1 ? success : failure
end
