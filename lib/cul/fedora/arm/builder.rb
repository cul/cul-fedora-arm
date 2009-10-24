
module Cul
  module Fedora
    module Arm

      # This class is for building ARM resource models in Fedora
      #
      # Authors::  James Stuart (mailto:james.stuart at columbia.edu), Benjamin Armintor (mailto: ba2213 at columbia.edu)
      # License::
      # Dependencies:: activesupport 
      
      class Builder

        # TODO: abstract this to allow for multiple patterns
        
        # list of columns for a template with no header row
        DEFAULT_TEMPLATE_HEADER = [:sequence, :target, :model_type, :source, :template_type, :dc_format, :id, :pid, :action, :license]
        
        # columns that must have values
        REQUIRED_COLUMNS = [:sequence]
        
        # columns that must be included in a template
        MANDATORY_COLUMNS = [:sequence, :target, :model_type]
        
        # list of columns which may have values
        VALID_COLUMNS = [:sequence, :target, :model_type, :source, :template_type, :dc_format, :id, :pid, :action, :license]

        FOXML_BUILDER = FoxmlBuilder.new()
        # array of individual hash: each hash corresponds to a metadata or resource.
        
        attr_reader :parts, :connector
        

        # creates a Builder object. Can be used with no arguments, or with ONE of the following options
        # [:template]:: builds parts based on an enumerable list of strings (for example, the result of File.open) 
        # [:header]:: designates for a template whether a header is specified
        # and one or more of the following:
        # [:host]:: designates a fedora host server name
        # [:admin_port]:: designates a fedora host port for admin
        # [:admin_ssl]:: designates whether ssl should be used
        
        # [:user]:: designates a fedora user
        # [:pwd]:: designates a fedora user credential
        def initialize(*args)
          options = args.extract_options!

          @parts = []
          @connector = options.delete(:connector)
          @namespace = options.delete(:ns)
          
          if (template = options.delete(:template)) || (file = options.delete(:file))
            template ||= File.open(file,"r")

            header = options.delete(:header) 
            header = true if header.nil?

            raise ArgumentError, "arguments should only include one of the following: :template, :file" unless options.empty?
            
            parse_template(template, header)
          else
            
            raise ArgumentError, "arguments should only include one of the following: :template, :file" unless options.empty?
          end
          
        end

        # adds one part to the parts array
        # arguments are a hash array of column name (underscored symbols) to values
        def add_part(*args)
          value_hash = args.extract_options!
          
          test_for_invalid_columns(value_hash.keys)
          test_for_required_columns(value_hash)
          
          raise "Sequence ID already taken" if part_by_sequence(value_hash[:sequence])
          
          @parts << value_hash
        end

        # looks for a part by :sequence key
        # note: if loading from a template, sequence will not be an integer, but rather a string
        def part_by_sequence(sequence_id)
          @parts.detect { |p| p[:sequence] == sequence_id}
        end
        # looks for a part by :pid key
        def part_by_pid(pid)
          @parts.detect { |p| p[:pid] == pid}
        end
        
        def purge(pid)
          if(@connector)
            purge = Tasks::PurgeTask.new(pid)
            purge.post(@connector)
          end
        end
        
        def process_parts()
          reserve_pids(parts)
          parts.each { |part_hash|
            process(part_hash)
          }
        end
        
        def process(value_hash)
          # part is a hash
          op = value_hash[:action] + "_" + value_hash[:model_type]
          op.downcase!
          op = op.intern
          raise "Unknown operation #{op}" unless method(op)
          return method(op).call(value_hash) 
        end
        
        def insert_aggregator(value_hash)
          data = FOXML_BUILDER.build(value_hash)
          task = Tasks::InsertFoxmlTask.new(data)
          task.post(@connector)
          task.response
        end
        def insert_metadata(value_hash)
          data = FOXML_BUILDER.build(value_hash)
          task = Tasks::InsertFoxmlTask.new(data)
          task.post(@connector)
          task.response
        end
        def insert_resource(value_hash)
          data = FOXML_BUILDER.build(value_hash)
          task = Tasks::InsertFoxmlTask.new(data)
          task.post(@connector)
          task.response
        end
       
        def reserve_pids(parts=@parts)
          assigned = []
          if (parts.nil?)
            return assigned
          end
          missing = 0
          # count missing pids
          parts.each { |part|
            test_for_required_columns(part)
            if ( part[:action].strip().eql?('insert'))
              if ( !part.has_key?(:pid) or part[:pid].strip().empty?)
                missing += 1
              end
            end
          }
          task = Tasks::ReservePidsTask.new(missing,@namespace)
          task.post(@connector)
          pids = (missing == 1)? [task.response.pid]:task.response.pid
          # assign new pids
          parts.each { |part|
            if ( part[:action].strip().eql?('insert'))
              if ( !part.has_key?(:pid) or part[:pid].strip().empty?)
                part[:pid] = pids.delete_at(0)
                assigned.push(part[:pid])
              end
            end
          }
          # make substitutions in target values
          parts.each { |part|
            if(part.has_key?(:target))
              target = part[:target]
              targets = target.split(';')
              targets.collect! { |t|
                if (t =~ /^\d+$/)
                  t = part_by_sequence(t)[:pid]
                end
                t
              }
              part[:target] = targets.join(';')
            end
          }
          assigned
        end



        protected
        

        # checks keys of a hash to make sure all elements of REQUIRED_COLUMNS are contained. 
        def test_for_required_columns(value_hash)
          missing_values = REQUIRED_COLUMNS.select { |col| !value_hash.has_key?(col) || value_hash[col].nil? }
          if (value_hash.has_key?(:action) and value_hash[:action].eql?('update'))
            raise "Update operations require a PID" unless (value_hash.has_key(:pid) and !value_hash[:pid].strip().eql?(''))
          end
          raise "Missing required values #{missing_values.join(",")}" unless missing_values.empty?
        end
        
        # checks list of column names to make sure every one is in VALID_COLUMNS 
        def test_for_invalid_columns(columns)
          invalid_columns = columns.select { |c| !VALID_COLUMNS.include?(c) }
          raise "Invalid column(s) found: #{invalid_columns.join(",")}" unless invalid_columns.empty?          
        end
        
        # parses an enumerable of strings to build parts
        # an optional header row specifies the columns, however sequence must be included and must be first
        # TODO: fix this to include a header option
        def parse_template(template, has_header_row)
          header_columns = DEFAULT_TEMPLATE_HEADER     # list of columns
          
          
          template.each_with_index do |line, i|
          
            # if first row, check for header
            if i == 0
              header_columns = line.split("\t").collect { |cn| cn.strip.underscore.to_sym } if has_header_row
              
              # check to make sure all mandatory columns are in the template
              missing_mandatory_columns = MANDATORY_COLUMNS.select { |c| !header_columns.include?(c) }
              raise "Missing mandatory column(s) found: #{missing_mandatory_columns.join(",")}" unless missing_mandatory_columns.empty?

              test_for_invalid_columns(header_columns)

              # skip header_row
              next if has_header_row

            end
            
            # create hash out of columns and whitespace-stripped values
            value_hash = Hash[*header_columns.zip(line.split("\t").collect(&:strip)).flatten]
            add_part(value_hash)
          end
          parts
        end
      end
    end
  end

end