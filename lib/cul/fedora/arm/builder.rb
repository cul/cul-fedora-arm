module Cul
  module Fedora
    module Arm
      class Builder
        DEFAULT_TEMPLATE_HEADER = [:sequence, :aggregate_under, :metadata, :metadata_type, :content, :content_type, :id, :license]
        
        REQUIRED_COLUMNS = [:sequence]
        MANDATORY_COLUMNS = [:sequence, :aggregate_under, :metadata]
        VALID_COLUMNS = [:sequence, :aggregate_under, :metadata, :metadata_type, :content, :content_type, :id, :license]

        attr_reader :parts
        
        def initialize(*args)
          options = args.extract_options!

          @parts = []

          
          if template = options.delete(:template)
            parse_template(template)
          end
          
          raise ArgumentError, "arguments should only include one of the following: :template" unless options.empty?
        end


        def add_part(*args)
          value_hash = args.extract_options!
          
          test_for_invalid_columns(value_hash.keys)
          test_for_required_columns(value_hash)
          
          raise "Sequence ID already taken" if part_by_sequence(value_hash[:sequence])
          
          @parts << value_hash
        end
        
        def part_by_sequence(sequence_id)
          @parts.detect { |p| p[:sequence] == sequence_id}
        end
        
        protected
        
        def test_for_required_columns(value_hash)
          missing_values = REQUIRED_COLUMNS.select { |col| !value_hash.has_key?(col) || value_hash[col].nil? }
          raise "Missing required values #{missing_values.join(",")}" unless missing_values.empty?
        end
        
        def test_for_invalid_columns(columns)
          invalid_columns = columns.select { |c| !VALID_COLUMNS.include?(c) }
          raise "Invalid column(s) found: #{invalid_columns.join(",")}" unless invalid_columns.empty?          
        end
        
        def parse_template(template)
          header_columns = []
          custom_header = false
          template.each_with_index do |line, i|
            # check for header
            if i == 0
              case line.to_s
              when /^[0-9]/
                header_columns = DEFAULT_TEMPLATE_HEADER
              when /^\w/
                custom_header = true
                header_columns = line.split("\t").collect { |cn| cn.strip.underscore.to_sym }
                raise "First column of custom designed headers must be sequence" unless header_columns[0] == :sequence
              end
              

              missing_mandatory_columns = MANDATORY_COLUMNS.select { |c| !header_columns.include?(c) }
              raise "Missing mandatory column(s) found: #{missing_mandatory_columns.join(",")}" unless missing_mandatory_columns.empty?

              test_for_invalid_columns(header_columns)

              next if custom_header

            end
            value_hash = Hash[*header_columns.zip(line.split("\t").collect(&:strip)).flatten]
            add_part(value_hash)
          end
          
          header_columns
        end
        
        
      end
    end
  end
end