require 'test_helper'
require 'test/helpers/soap_inputs'


class CulFedoraArmTasksTest < Test::Unit::TestCase
  context "test next pid(s) reservation task on localhost" do
    setup do
      @driver = getSOAPDriver("127.0.0.1","8080",'user','pwd')
      @numPids = 3
      @ns = "test"
      @task = Cul::Fedora::Arm::Tasks::ReservePidsTask.new(@numPids,@ns)
    end
    should "return expected output when executed" do
      assert_nothing_raised [(response = @task.post(@driver))] do
      #  raise "execution output comparison not implemented"
        puts response.pid
      end
      assert_equal @numPids, response.pid.length
      response.pid.each {|p| assert_equal 0, p.index(@ns)}
    end  
  end
  context "test metadata update SOAP message generation" do
    setup do
      @task = Cul::Fedora::Arm::Tasks::UpdateMODSTask.new("test:13","CONTENT",METADATA_MODS_TEST)
      @expectedInput = MODIFY_MODS_SOAP_MESSAGE
      @expectedOutput
    end
  end
  context "test DC metadata update" do
    setup do
      @driver = getSOAPDriver("127.0.0.1","8080",'fedoraAdmin','fedoarPassword')
      src = "/var/tmp/foo.dc.xml"
      @expectedInput = sprintf(METADATA_DC_TEST, src)
      @task = Cul::Fedora::Arm::Tasks::UpdateDCTask.new("ldpd:1",@expectedInput)
      @expectedOutput
    end
    should "match expected SOAP output" do
      assert_nothing_raised [(response = @task.post(@driver))] do
        puts response
      end
      modifiedDate = DateTime.parse(response.modifiedDate)
      now = DateTime.new()
      diff = now - modifiedDate
      assert diff < 2 # assert that the update time was within a couple of seconds
    end
    should "have updated the datastream correctly" do
      
    end
  end
  def getSOAPDriver(host,port,user,pwd)
          endpoint = "http://#{host}:#{port}/fedora/services/management"
          wsdl = "http://#{host}:#{port}/fedora/wsdl?api=API-M"
          result = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
          result.options["protocol.http.basic_auth"]<<[endpoint,user,pwd]
          result
  end
end