##
## The new version of ruby_debug uses this, and it looks like it was removed.
## I've replaced it here.
##
class String
  def is_binary_data?
    ( self.count( "^ -~", "^\r\n" ).fdiv(self.size) > 0.3 || self.index( "\x00" ) ) unless empty?
  end
end
