require 'test_helper'
require 'digest/md5'

class CulFedoraArmBuilderTest < Test::Unit::TestCase
  TEST = 'test'
  CASE1 = "#{TEST}/fixtures/case1"
  CASE2 = "#{TEST}/fixtures/case2"
  CASE3 = "#{TEST}/fixtures/case3"
  CASE4 = "#{TEST}/fixtures/case4"

  context "Given the 'test_config' fedora instance " do
    setup do
      @connector = Cul::Fedora::Connector.parse(YAML::load_file("private/fedora-config.yml"))["test_config"]
    end
  
    should "build a connector properly" do
      assert_kind_of Cul::Fedora::Connector, @connector
    end

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
        assert_equal @builder_class::DEFAULT_TEMPLATE_HEADER, [:sequence, :target, :model_type, :source, :template_type, :dc_format, :id, :pid, :action, :license]
      end


      should "have a list of mandatory, valid, and required columns" do
        assert_instance_of  Array, @builder_class::REQUIRED_COLUMNS

        assert_equal @builder_class::REQUIRED_COLUMNS, [:sequence]
        assert_equal @builder_class::MANDATORY_COLUMNS, [:sequence, :target, :model_type]
        assert_equal @builder_class::VALID_COLUMNS, [:sequence, :target, :model_type, :source, :template_type, :dc_format, :title_attr, :mime, :id, :pid, :action, :license]
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
          @builder.add_part(:sequence => "0", :target => "collection:1;ac:5", :source => "/test-0001.xml", :model_type => "Metadata")
        end

        should "not add parts without a sequence" do
          assert_raise RuntimeError, "Missing required values sequence" do
            @builder.add_part(:target => "collection:1;ac:5", :source => "/test-0001.xml")
          end
        end

        should "not add parts with the same sequence id" do

          assert_raise(RuntimeError, "Sequence ID already taken") do
            @builder.add_part(:sequence => "2", :source => "/test-0001.xml", :model_type => "Metadata")
            @builder.add_part(:sequence => "2", :source => "/test-0002.xml", :model_type => "Metadata")
          end

        end
      end

      context "given headers for templates" do
        setup do
          @good_header = %w{sequence target model_type source template_type dc_format id}
          @invalid_column = %w{sequence target model_type random}
          @sequence_not_first = %w{target model_type sequence}
          @missing_mandatory = %w{sequence target template_type}
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
          @builder = @builder_class.new(:file => "#{CASE1}/builder-template.txt")
          @builder_via_template_option = @builder_class.new(:template => File.open("#{CASE1}/builder-template.txt", "r"))
          @builder_no_header = @builder_class.new(:file => "#{CASE1}/builder-template-noheader.txt", :header => false)
        end

        should "load successfully" do
          assert_instance_of @builder_class, @builder
          assert_instance_of @builder_class, @builder_no_header
        end

        should "have equivalent results for header and no_header instances of the default column set" do
          @builder.parts.each{|part|
            assert_equal part, @builder_no_header.part_by_sequence(part[:sequence])
          }
          assert_equal @builder.parts.length, @builder_no_header.parts.length
        end

        should "have equivalent results for opening via template and file" do
          assert_equal @builder.parts, @builder_via_template_option.parts
        end


        should "ignore the header row and load template data successfully" do
          assert_equal @builder.parts.length, 6
          assert_equal @builder.parts[2][:source],  "/test-0001.xml"
          assert_equal @builder.parts[3][:license],  "license:by-nc-nd"
        end

        should "have parts accessible by sequence id" do
          assert_kind_of Hash, @builder.part_by_sequence("6")
          assert_equal @builder.parts[4], @builder.part_by_sequence("6")
        end
      end

      context "with an example template with header, and fedora credentials" do
        setup do
          args = {:file => "#{CASE1}/builder-template.txt", :connector => @connector}
          @builder = @builder_class.new(args)
          @builder_via_template_option = @builder_class.new(:template => File.open("#{CASE1}/builder-template.txt", "r"))
          @builder_no_header = @builder_class.new(:file => "#{CASE1}/builder-template-noheader.txt", :header => false)
        end

        should "load successfully" do
          assert_instance_of @builder_class, @builder
          assert_instance_of @builder_class, @builder_no_header
        end

        should "have equivalent results for header and no_header instances of the default column set" do
          @builder.parts.each{|part|
            assert_equal part, @builder_no_header.part_by_sequence(part[:sequence])
          }
          assert_equal @builder.parts.length, @builder_no_header.parts.length
        end

        should "have equivalent results for opening via template and file" do
          assert_equal @builder.parts, @builder_via_template_option.parts
        end


        should "ignore the header row and load template data successfully" do
          assert_equal @builder.parts.length, 6
          assert_equal @builder.parts[2][:source],  "/test-0001.xml"
          assert_equal @builder.parts[3][:license],  "license:by-nc-nd"
        end

        should "have parts accessible by sequence id" do
          assert_kind_of Hash, @builder.part_by_sequence("6")
          assert_equal @builder.parts[4], @builder.part_by_sequence("6")
        end

        should "be able to procure PIDs for parts in sequence" do
          @builder.reserve_pids()
          @builder.parts.each { |part|
            assert part.has_key?(:pid)
            assert !(part[:pid].empty?)
            assert_match /^\w+:\d+$/, part[:pid]
            targets = part[:target].split(';')
            targets.each {|target|
              assert_no_match /^\d+$/, target
            }
          }
        end
      end
      context "with example input with header for two inserted aggregators, and fedora credentials" do
        setup do
          args = {:file => "#{CASE2}/builder-template.txt",:ns=>'test', :connector => @connector}
          @builder = @builder_class.new(args)
          @builder_via_template_option = @builder_class.new(:template => File.open("#{CASE1}/builder-template.txt", "r"))
        end
        should "be able to ingest aggregators into repository" do
          # do ingest
          @assigned = @builder.reserve_pids()  
          if (@assigned)
            @assigned.each {|pid|
              assert @builder.part_by_pid(pid), "Could not find part assigned to #{pid}"
            }          
          end
          response = @builder.process_parts()

          # get objects, verify properties
          if (@assigned)
            @connector.rest_interface do |http|
              @assigned.each { |pid| 
                resp = http.head("/fedora/get/#{pid}/DC")
                assert_equal "200", resp.code,  "#{pid} not loaded correctly to repo at #{@connector.rest_location}... #{resp.code} #{resp.message} "
              }
            end
          end
        end
        teardown do
          # purge objects
          if (@assigned)
            @assigned.each {|pid|
              begin
                @builder.purge(pid)
              rescue Exception=>e
                puts "Error purging #{pid}: #{e}"
              end
            }
          end
        end
      end
      context "with example input with header for an inserted metadata, and fedora credentials" do
        setup do
          infile_path = "#{CASE4}/builder-template.txt"
          b = binding
          template = File.open(infile_path) {|f|
            f.readlines().collect{ |line|
              line.gsub(/\#\{(\w+)\}/) {|match| eval($1, b)}
            }
          }
          args = {:template => template,:ns=>'test', :connector => @connector}
          @builder = @builder_class.new(args)
          @builder_via_template_option = @builder_class.new(:template => File.open("#{CASE4}/builder-template.txt", "r"))
        end
        should "be able to ingest metadata objects into repository" do
          # do ingest
          @assigned = @builder.reserve_pids()  
          if (@assigned)
            @assigned.each {|pid|
              assert @builder.part_by_pid(pid), "Could not find part assigned to #{pid}"
            }          
          end
          response = @builder.process_parts()

          # get objects, verify properties
          if (@assigned)
            @connector.rest_interface do |http|
              @assigned.each { |pid| 
                resp = http.get("/fedora/get/#{pid}/CONTENT")
                assert_equal "200", resp.code,  "#{pid} not loaded correctly to repo at #{@connector.rest_location}... #{resp.code} #{resp.message} "
                eTitle = "<title>test record title</title>"
                assert resp.body.index(eTitle), "did not find expected mods title tag #{eTitle} in #{pid}/CONTENT"
                resp = http.get("/fedora/get/#{pid}/DC")
                assert_equal "200", resp.code,  "#{pid} not loaded correctly to repo at #{@connector.rest_location}... #{resp.code} #{resp.message} "
                eTitle = "<dc:title>test record title</dc:title>"
                assert resp.body.index(eTitle), "did not find expected title tag #{eTitle} in #{pid}/DC"
              }
            end
          end
        end
        teardown do
          # purge objects
          if (@assigned)
            @assigned.each {|pid|
              begin
                @builder.purge(pid)
              rescue Exception=>e
                puts "Error purging #{pid}: #{e}"
              end
            }
          end
        end
      end
      context "with example input with header for an inserted resource, and fedora credentials" do
        setup do
          infile_path = "#{CASE3}/builder-template.txt"
          b = binding
          template = File.open(infile_path) {|f|
            f.readlines().collect{ |line|
              line.gsub(/\#\{(\w+)\}/) {|match| eval($1, b)}
            }
          }
          args = {:template => template,:ns=>'test', :connector => @connector}
          @builder = @builder_class.new(args)
          @builder_via_template_option = @builder_class.new(:template => File.open("#{CASE3}/builder-template.txt", "r"))
        end
        should "be able to ingest resource objects into repository" do
          # do ingest
          @assigned = @builder.reserve_pids()  
          if (@assigned)
            @assigned.each {|pid|
              assert @builder.part_by_pid(pid), "Could not find part assigned to #{pid}"
            }          
          end
          response = @builder.process_parts()
          
          # get objects, verify properties
          if (@assigned)
            @connector.rest_interface do |http|
              @assigned.each { |pid| 
                resp = http.head("/fedora/get/#{pid}/DC")
                assert_equal "200", resp.code,  "#{pid}/DC not loaded correctly to repo at #{@connector.rest_location}... #{resp.code} #{resp.message} "
                resp = http.get("/fedora/get/#{pid}/CONTENT")
                assert_equal "200", resp.code,  "#{pid}/CONTENT not loaded correctly to repo at #{@connector.rest_location}... #{resp.code} #{resp.message} "
                actual = resp.body
                begin
                  expected = File.open(@builder.part_by_pid(pid)[:source],'rb')
                  a_digest = Digest::MD5.hexdigest(actual)
                  e_digest = Digest::MD5.hexdigest(expected.read())
                  assert_equal e_digest, a_digest
                ensure
                  expected.close()
                end
                resp = http.get("/fedora/get/#{pid}/RELS-EXT")
                assert_equal "200", resp.code,  "#{pid}/RELS-EXT not loaded correctly to repo at #{@connector.rest_location}... #{resp.code} #{resp.message} "
                rels = resp.body
                assert rels.index("<dcmi:extent>15138</dcmi:extent>") > -1
                http.finish()
              }
            end
          end
        end
        teardown do
          # purge objects
          if (@assigned)
            @assigned.each {|pid|
              begin
                @builder.purge(pid)
              rescue Exception=>e
                puts "Error purging #{pid}: #{e}"
              end
            }
          end
        end
      end
    end
  end
end