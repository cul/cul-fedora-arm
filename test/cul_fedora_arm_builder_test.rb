require 'test_helper'
require 'test/helpers/template_builder'


class CulFedoraArmBuilderTest < Test::Unit::TestCase
  
  context "The builder class" do
    setup do
      @builder_class = Cul::Fedora::Arm::Builder
    end
  
    should "have a blank read_only array of parts" do
      @builder = @builder_class.new
      
      assert_instance_of @builder_class, @builder
      assert_equal [], @builder.parts
      assert_raise NoMethodError do
        @builder.parts = [:test]
      end
    end

    should "have a default array of columns for templates without headers" do
      assert_equal @builder_class::DEFAULT_TEMPLATE_HEADER, [:sequence, :aggregate_under, :metadata, :metadata_type, :content, :content_type, :id, :license]
    end
    
    
    should "have a list of mandatory, valid, and required columns" do
      assert_instance_of  Array, @builder_class::REQUIRED_COLUMNS

      assert_equal @builder_class::REQUIRED_COLUMNS, [:sequence]
      assert_equal @builder_class::MANDATORY_COLUMNS, [:sequence, :aggregate_under, :metadata]
      assert_equal @builder_class::VALID_COLUMNS, [:sequence, :aggregate_under, :metadata, :metadata_type, :content, :content_type, :id, :license]
    end
    
    should "accept only options :template or :file" do
      assert_instance_of @builder_class, @builder_class.new(:template => nil)
      assert_instance_of @builder_class, @builder_class.new(:file => nil)

      assert_raise(ArgumentError) do
        @builder_class.new(:template => nil, :invalid => true)
      end

      assert_raise(ArgumentError) do
        @builder_class.new(:template => "test", :file => "test")
      end

    end

    should "not accept :header without :template" do
      assert_raise(ArgumentError) do
        @builder_class.new(:header => true)
      end
    end


    context "given a blank builder" do
      setup do
        @builder = @builder_class.new        
      end
      
      should "have a blank array of parts" do
        assert_equal @builder.parts, []
      end
      
      should "be able to add parts" do
        @builder.add_part(:sequence => "0", :aggregate_under => "collection:1;ac:5", :metadata => "/test-0001.xml")
      end

      should "not add parts without a sequence" do
        assert_raise RuntimeError, "Missing required values sequence" do
          @builder.add_part(:aggregate_under => "collection:1;ac:5", :metadata => "/test-0001.xml")
        end
      end
      
      should "not add parts with the same sequence id" do
        
        assert_raise(RuntimeError, "Sequence ID already taken") do
          @builder.add_part(:sequence => "2", :metadata => "/test-0001.xml")
          @builder.add_part(:sequence => "2", :metadata => "/test-0002.xml")
        end
        
      end
    end

    context "given headers for templates" do
      setup do
        @good_header = %w{sequence aggregateUnder metadata metadataType content contentType id}
        @invalid_column = %w{sequence aggregateUnder metadata random}
        @sequence_not_first = %w{aggregateUnder metadata sequence}
        @missing_mandatory = %w{sequence aggregateUnder metadataType}
      end

      should "accept good headers" do
        assert_instance_of @builder_class, @builder_class.new(:template => template_builder(@good_header))
      end
      
      should "accept blank template" do
        assert_nothing_raised do
          @builder_class.new(:template => nil)
        end
      end
      
      should "reject invalid column names" do
        assert_raise RuntimeError, "Invalid column name: random"  do
          @builder_class.new(:template => template_builder(@invalid_column))
        end
      end
      
      should "insist on all mandatory columns" do
        assert_raise RuntimeError, "Missing mandatory column: metadata" do
          @builder_class.new(:template => template_builder(@missing_mandatory))
        end
      end
    end
    
    context "with an example template with header" do
      setup do
        @builder = @builder_class.new(:file => "test/fixtures/case1/builder-template.txt")
        @builder_via_template_option = @builder_class.new(:template => File.open("test/fixtures/case1/builder-template.txt", "r"))
        @builder_no_header = @builder_class.new(:file => "test/fixtures/case1/builder-template-noheader.txt", :header => false)
      end
      
      should "load successfully" do
        assert_instance_of @builder_class, @builder
        assert_instance_of @builder_class, @builder_no_header
      end
      
      should "have equivalent results for header and no_header instances of the default column set" do
        assert_equal @builder.parts, @builder_no_header.parts
      end

      should "have equivalent results for opening via template and file" do
        assert_equal @builder.parts, @builder_via_template_option.parts
      end

      
      should "ignore the header row and load template data successfully" do
        assert_equal @builder.parts.length, 4
        assert_equal @builder.parts[0][:metadata],  "/test-0001.xml"
        assert_equal @builder.parts[3][:license],  "http://creativecommons.org/licenses/by-nc-nd/3.0/us/"
      end

      should "have parts accessible by sequence id" do
        assert_kind_of Hash, @builder.part_by_sequence("5")
        assert_equal @builder.parts[3], @builder.part_by_sequence("5")
      end
    end
    
  end
  
  
end

