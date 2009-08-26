

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
        DEFAULT_TEMPLATE_HEADER = [:sequence, :aggregate_under, :metadata, :metadata_type, :content, :content_type, :id, :license]
        
        # columns that must have values
        REQUIRED_COLUMNS = [:sequence]
        
        # columns that must be included in a template
        MANDATORY_COLUMNS = [:sequence, :aggregate_under, :metadata]
        
        # list of columns which may have values
        VALID_COLUMNS = [:sequence, :aggregate_under, :metadata, :metadata_type, :content, :content_type, :id, :license]


        # array of individual hash: each hash corresponds to a metadata or resource.
        attr_reader :parts
        

        # creates a Builder object. Can be used with no arguments, or with ONE of the following options
        # [:template]:: builds parts based on an enumerable list of strings (for example, the result of File.open) 
        def initialize(*args)
          options = args.extract_options!

          @parts = []

          # TODO: add file option to avoid :template => File.open(file_name,"r")
          
          if template = options.delete(:template)
            parse_template(template)
          end
          
          raise ArgumentError, "arguments should only include one of the following: :template" unless options.empty?
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
        
        protected
        

        # checks keys of a hash to make sure all elements of REQUIRED_COLUMNS are contained. 
        def test_for_required_columns(value_hash)
          missing_values = REQUIRED_COLUMNS.select { |col| !value_hash.has_key?(col) || value_hash[col].nil? }
          raise "Missing required values #{missing_values.join(",")}" unless missing_values.empty?
        end
        
        # checks list of column names to make sure every one is in VALID_COLUMNS 
        def test_for_invalid_columns(columns)
          invalid_columns = columns.select { |c| !VALID_COLUMNS.include?(c) }
          raise "Invalid column(s) found: #{invalid_columns.join(",")}" unless invalid_columns.empty?          
        end
        
        # parses an enumerable of strings to build parts
        # an optional header row specifies the columns, however sequence must be included and must be first
        def parse_template(template)
          header_columns = []     # list of columns
          custom_header = false   # indicates whether a header_row was used
          
          
          template.each_with_index do |line, i|
          
            # if first row, check for header
            if i == 0
          
              # assumes that if the first character is a letter, this is a header row, otherwise, use default_columns
              case line.to_s
              when /^[0-9]/
                header_columns = DEFAULT_TEMPLATE_HEADER
              when /^\w/
                custom_header = true
                header_columns = line.split("\t").collect { |cn| cn.strip.underscore.to_sym }
                raise "First column of custom designed headers must be sequence" unless header_columns[0] == :sequence
              end
              

              # check to make sure all mandatory columns are in the template
              missing_mandatory_columns = MANDATORY_COLUMNS.select { |c| !header_columns.include?(c) }
              raise "Missing mandatory column(s) found: #{missing_mandatory_columns.join(",")}" unless missing_mandatory_columns.empty?

              test_for_invalid_columns(header_columns)

              # skip header_row
              next if custom_header

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