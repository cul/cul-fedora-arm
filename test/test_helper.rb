require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'factory_girl'
require 'activesupport'
require 'helpers/soap_inputs'
require 'helpers/template_builder'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift('./lib')
$LOAD_PATH.unshift('./test')

require 'cul-fedora-arm'
require 'cul/fedora/image/image'
class ActiveSupport::TestCase
end

