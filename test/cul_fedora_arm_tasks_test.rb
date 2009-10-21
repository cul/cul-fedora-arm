require 'test_helper'
require 'net/http'
require 'net/https'

class CulFedoraArmTasksTest < Test::Unit::TestCase
  context "Given the 'test_config' fedora instance " do
    setup do
      @connector = Cul::Fedora::Connector.parse(YAML::load_file("private/fedora-config.yml"))["test_config"]
    end
  
    should "build a connector properly" do
      assert_kind_of Cul::Fedora::Connector, @connector
    end

  
    context "test next pid(s) reservation task on localhost" do
      setup do
        @numPids = 3
        @ns = "test"
        @task = Cul::Fedora::Arm::Tasks::ReservePidsTask.new(@numPids,@ns)
      end
      should "return expected output when executed" do
        assert_nothing_raised [(response = @task.post(@connector))] do
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
        @src = DateTime.new().strftime("dublincore-%Y%m%dT%H%M%S.xml")
        @expectedInput = sprintf(METADATA_DC_TEST, @src)
        @task = Cul::Fedora::Arm::Tasks::UpdateDCTask.new(@pid,@expectedInput)
      end
      should "match expected SOAP output" do
        assert_nothing_raised [(response = @task.post(@connector))] do
        end
        modifiedDate = DateTime.parse(response.modifiedDate)
        now = DateTime.new()
        diff = now - modifiedDate
        assert diff < 2 # assert that the update time was within a couple of seconds
      end
      should "have updated the datastream correctly" do
        @connector.rest_interface do |http|
          response = http.get("/fedora/get/#{@pid}/DC")
          assert response.body.rindex("<dc:source>#{@src}</dc:source>")
        end
      end
    end
  end
end