require 'test_helper'
require 'net/http'

class CulFedoraArmTasksTest < Test::Unit::TestCase
  def initialize(test_method_name)
    super(test_method_name)
    @local = {}
    File.open('../test/local.properties','r').each {|line|
      line.strip!
      if (line.index('#').nil? or line.index('#') != 0)
        ix = line.index('=')
        if (ix)
          @local[line[0...ix].intern] = line[ix+1..-1]
        end
      end
    }
  end
  context "test next pid(s) reservation task on localhost" do
    setup do
      @driver = getSOAPDriver(@local[:host],@local[:port],@local[:user],@local[:pwd])
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
  context "test DC metadata update against local host" do
    setup do
      @pid = 'ldpd:1'
      @driver = getSOAPDriver(@local[:host],@local[:port],@local[:user],@local[:pwd])      
      @src = DateTime.new().strftime("dublincore-%Y%m%dT%H%M%S.xml")
      @expectedInput = sprintf(METADATA_DC_TEST, @src)
      @task = Cul::Fedora::Arm::Tasks::UpdateDCTask.new(@pid,@expectedInput)
    end
    should "match expected SOAP output" do
      assert_nothing_raised [(response = @task.post(@driver))] do
        puts "nothing raised? " + response
        puts response.body
      end
      modifiedDate = DateTime.parse(response.modifiedDate)
      now = DateTime.new()
      diff = now - modifiedDate
      assert diff < 2 # assert that the update time was within a couple of seconds
    end
    should "have updated the datastream correctly" do
      response = Net::HTTP.new(@local[:host],@local[:port]).get("/fedora/get/#{@pid}/DC")
      assert response.body.rindex("<dc:source>#{@src}</dc:source>")
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