# Dir.exist?
# Dir/self.existQ

# 2011.03.11
# 0.0.0

class Dir
  
  def self.exist?(directory_name)
    File.directory?(directory_name)
  end
  
end
