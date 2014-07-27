# File/self.basename_without_extname.rb
# File.basename_without_extname

# 20140408, 12
# 0.1.0

# Description: This returns the basename without the extension for a given File instance without the need to specify what the extension is because it makes use of File.extname which works that out.

# Changes:
# 1. - require 'File/self.extname', since this is built-in now and has been for so many years I wonder why I wrote it at all.

class File

  def self.basename_without_extname(path)
    basename(path, extname(path))
  end

end
