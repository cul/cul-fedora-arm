require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'factory_girl'
require 'activesupport'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'cul-fedora-arm'

class ActiveSupport::TestCase
end

