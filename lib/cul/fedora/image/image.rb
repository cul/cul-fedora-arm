require 'net/http'
require 'tempfile'
require 'stringio'
module Cul
    module Fedora
        module Image
          WIDTH_TEMPLATE = '<si-basic:imageWidth>%s</si-basic:imageWidth>'
          LENGTH_TEMPLATE = '<si-basic:imageLength>%s</si-basic:imageLength>'
          XSAMPLING_TEMPLATE = '<si-assess:xSamplingFrequency>%s</si-assess:xSamplingFrequency>'
          YSAMPLING_TEMPLATE = '<si-assess:ySamplingFrequency>%s</si-assess:ySamplingFrequency>'
          SAMPLINGUNIT_CM = '<si-assess:samplingFrequencyUnit rdf:resource="http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/ASSESSMENT/CentimeterSampling" />'
          SAMPLINGUNIT_IN = '<si-assess:samplingFrequencyUnit rdf:resource="http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/ASSESSMENT/InchSampling" />'
          SAMPLINGUNIT_NA = '<si-assess:samplingFrequencyUnit rdf:resource="http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/ASSESSMENT/NoAbsoluteSampling" />'
          UNITS = {:inch => SAMPLINGUNIT_IN, :cm => SAMPLINGUNIT_CM}
          SIZE_TEMPLATE = '<dcmi:extent>%s</dcmi:extent>'
          # magic bytes
          # 2 bytes signatures
          BITMAP = [0x42,0x4d] # "BM"
          JPEG = [0xff,0xd8]
          # 4 byte signatures
          TIFF_BE = [0x49,0x49,0x2A,0] # "II*\x00"
          TIFF_LE = [0x4d,0x4d,0,0x2A] # "MM\x00*"
          GIF = [0x47,0x49,0x46,0x38] # "GIF8"
          # 8 byte signatures
          PNG = [0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]
          def analyze_image(file_name, debug=false)
            result = {}
            file = nil
            file_size = 0
            if (file_name.index("http://") == 0)
              temp_file = Tempfile.new("image-download")
              #download the url content, write to tempfile
              file = temp_file
            else
              file = File.open(file_name,'rb')
            end
            result[:size] = file_size = File.size(file.path)
            # get properties
            header = []
            8.times {
              header.push(file.getc())
            }  
            case
            when header[0..1].eql?(BITMAP):
              file.rewind()
              result.merge!(analyze_bitmap(file,debug))
            when header[0..1].eql?(JPEG):              file.rewind()
              result.merge!(analyze_jpeg(file,debug))
            when header[0..3].eql?(TIFF_LE), header[0..3].eql?(TIFF_BE):
              file.rewind()
              result.merge!(analyze_tiff(file,debug))
            when header[0..3].eql?(GIF):
              file.rewind()
              result.merge!(analyze_gif(file,debug))
            when header.eql?(PNG):
              file.rewind()
              result.merge!(analyze_png(file,debug))
            else
              msg = ''
              header.each {|c|
                msg += c.to_s(16)
                msg += ' '
              }
              puts "\nUnmatched header bytes: " + msg
            end
            file.close()
            # return hash
            result
          end
          
          def analyze_gif(file,debug)
            props = {}
            header = file.read(13)
            width = header[6...8].unpack('v')[0]
            length = header[8...10].unpack('v')[0]
            par = header[12]
            props[:width] = width
            props[:length] = length
            props[:mime] = 'image/gif'
            props             
          end
          
          def analyze_png(file,debug)
            result = {}
            size = File.size(file.path)
            file.read(8) # skip signature
            while (file.pos < size - 1) do
                len_bytes = file.read(4)
                length = len_bytes.unpack('N')[0]
                ctype = file.read(4)
                case
                when 'pHYs'.eql?(ctype):
                  val = file.read(length)
                  xsam = val[0..3].unpack('N')[0]
                  ysam = val[4..7].unpack('N')[0]
                  unit = val[8].unpack('C')
                  if (unit ==1)
                    result[:sampling_unit] = :cm
                    xsam = xsam/100
                    ysam = ysam/100
                  end
                  result[:x_sampling] = xsam
                  result[:y_sampling] = ysam
                  file.seek(4,IO::SEEK_CUR)
                when 'IHDR'.eql?(ctype):
                  val = file.read(length)
                  result[:width] = val[0..3].unpack('N')[0]                  
                  result[:length] = val[4..7].unpack('N')[0]                  
                  file.seek(4,IO::SEEK_CUR)
                else
                  file.seek(4,IO::SEEK_CUR)
                end              
            end
            result
          end
          def analyze_bitmap(file,debug)
            result = {}
            file.seek(0x12,IO::SEEK_CUR)
            width = file.read(4).unpack('V')[0]
            length = file.read(4).unpack('V')[0]
            file.seek(0x0c,IO::SEEK_CUR)
            xsam = file.read(4).unpack('V')[0]
            ysam = file.read(4).unpack('V')[0]
            xsam /= 100 # ppm -> ppc
            ysam /= 100 # ppm -> ppc
            result[:mime] = 'image/bmp'
            result[:sampling_unit] = :cm
            result[:x_sampling] = xsam
            result[:y_sampling] = ysam
            result[:width] = width
            result[:length] = length
            result
          end
=begin
            TIFF Format notes taken from http://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf
            Header format:
            Bytes 0-1: BOM. [0x49,0x49] = LittleEndian, [0x4d,0x4d] = BigEndian
            Bytes 2-3: Format marker (42) in the byte order indicated previously
            Bytes 4-7: Byte offset of the first IFD, relative to file beginning
            IFD format:
            Bytes 0-1: Number of 12-byte IFD Entries
            [IFD Entries]
            Bytes -4 - -1: Byte offset of next IFD, or 0 if none remain
            IFD Entry Format:
            Bytes 0-1: Tag
            Bytes 2-3: Type
              1 = BYTE (unsigned 8-bit integer)
              2 = ASCII (8 bit byte containing 7-bit char code)
              3 = SHORT (16-bit unsigned integer)
              4 = LONG (32-bit unsigned integer)
              5 = RATIONAL (Two LONGs, first is numerator, second denominator)
            Bytes 4-7: Num values of indicated Type
            Bytes 8-11: Value offset
=end
          def analyze_tiff(file,debug)
            result = {:mime=>'image/tiff'}
            littleEndian = [0x49,0x49].eql?(file.read(2))
            file.seek(2,IO::SEEK_CUR)
            nextIFD = littleEndian ? file.read(4).unpack('V')[0] : file.read(4).unpack('N')[0]
            result.merge!(analyze_exif(file,nextIFD,littleEndian,debug))
            result
          end
          
          
          JPEG_NO_PAYLOAD = (0xd0..0xd9)
          JPEG_APP = (0xe0..0xef)
          JPEG_VARIABLE_PAYLOAD = [0xc0,0xc2,0xc4,0xda,0xdb,0xfe]
          def analyze_jpeg(file,debug)
            result = {:mime => 'image/jpeg'}
            while ((header = file.read(2)) and not "\xff\xd9".eql?(header))
              case
              when 0xdd.eql?(header[1]):
                payload = nil
                file.seek(2,IO::SEEK_CUR)
              when JPEG_APP.member?(header[1]), JPEG_VARIABLE_PAYLOAD.member?(header[1]):
                len = file.read(2).unpack('n')[0]
                if ("\xff\xe0".eql?(header)): # APP0 segment - JFIF
                  puts "JFIF file segment detected" if debug
                  payload = file.read(len)
                  id = payload[0..4]
                  version = payload[5..6]
                  unit = payload[7]
                  x_sample = payload[8..9].unpack('n')[0]
                  y_sample = payload[10..11].unpack('n')[0]
                  result[:x_sampling] = x_sample
                  result[:y_sampling] = y_sample
                  if (unit == "\x01"): result[:sampling_unit] = :inch
                  elsif (unit == "\x02"): result[:sampling_unit] = :cm
                  end
                elsif ("\xff\xe1".eql?(header)): # APP1 segment - EXIF
                  puts "EXIF file segment detected" if debug
                  payload = file.read(len)
                  result.merge!(analyze_exif(StringIO.new(payload),0,false,debug))
                elsif (header[1] >= 0xc0 and header[1] <= 0xc3)
                  payload = file.read(len)
                  precision = payload[0]
                  length = payload[1..2].unpack('n')[0]
                  width = payload[3..4].unpack('n')[0]
                  result[:width] = width
                  result[:length] = length
                else
                  file.seek(len,IO::SEEK_CUR)
                end
              else
                payload = nil?              end
            end
            result
          end
          
          def analyze_exif(file,nextIFD,littleEndian,debug=false)
            result = Hash.new()
            until (nextIFD == 0) do
              file.seek(nextIFD,IO::SEEK_SET)
              bytes = file.read(2)
              numEntries = littleEndian ? bytes.unpack('v')[0] : bytes.unpack('n')[0]
              entries = Hash.new()
              numEntries.times do
                if (littleEndian)
                  tag = file.read(2).unpack('v')
                  ttype = file.read(2).unpack('v')[0]
                  numValues = file.read(4).unpack('V')[0]
                  valueOffsetBytes = file.read(4)
                  valueOffset = valueOffsetBytes.unpack('V')[0]
                else
                  tag = file.read(2).unpack('n')[0]
                  ttype = file.read(2).unpack('n')[0]
                  numValues = file.read(4).unpack('N')[0]
                  valueOffsetBytes = file.read(4)
                  valueOffset = valueOffsetBytes.unpack('N')[0]
                end
                if (debug)
                  puts "\ntag : #{tag.to_s(16)} ttype: #{ttype.to_s(16)} numValues: #{numValues} valueOffset: #{valueOffset}"
                end

                nextEntry = file.tell()
                values = []
                if (1 <= ttype and ttype <= 5 and numValues > 0)
                  case
                  when ttype == 1: # unsigned bytes
                    if (numValues > 4)
                      file.seek(valueOffset,IO::SEEK_SET)
                      values = file.read(numValues)
                    else
                      values = valueOffsetBytes
                    end
                    values = values.unpack('C*')
                  
                  when ttype == 2:
                    if (numValues > 4)
                      file.seek(valueOffset,IO::SEEK_SET)
                      values = file.read(numValues)
                    else
                      values = valueOffsetBytes
                    end
                    values = values.unpack('C*')
                    values.collect! {|c|
                      c.to_chr
                    }
                  when ttype == 3:
                    if (numValues > 2)
                      file.seek(valueOffset,IO::SEEK_SET)
                      values = file.read(numValues * 2)
                    else
                      values = valueOffsetBytes
                    end
                    values = littleEndian ? values.unpack('v*'):values.unpack('n*')
                  when ttype == 4:
                    if (numValues > 1)
                      file.seek(valueOffset,IO::SEEK_SET)
                      values = file.read(numValues * 4)
                    else
                      values = valueOffsetBytes
                    end
                    values = littleEndian ? values.unpack('V*'):values.unpack('N*')
                  when ttype == 5:
                    # RATIONAL: a sequence of pairs of 32-bit integers, numerator and denominator
                    file.seek(valueOffset,IO::SEEK_SET)
                    values = file.read(numValues * 8)
                    if(values.length % 8) != 0:
                      raise "Unexpected end of bytestream when reading EXIF data"
                    end
                    values = littleEndian ? values.unpack('V*'):values.unpack('N*')
                    values = (0...values.length).step(2).collect {|ix|
                      values[ix].quo(values[(ix)+1])
                    }
                  else
                    if debug: puts "Unknown tag type: #{ttype}"
                    end
                  end
                entries[tag] = values
                end
                file.seek(nextEntry,IO::SEEK_SET)                
              end
              nextIFD = littleEndian ? file.read(4).unpack('V')[0] : file.read(4).unpack('N')[0]
            end
            if (entries.has_key?(0x0100))
              result[:width] = entries[0x0100][0]
            end
            if (entries.has_key?(0x0101))
              result[:length] = entries[0x0101][0]
            end
            if (entries.has_key?(0x011a))
              result[:x_sampling] = entries[0x011a][0]
            end
            if (entries.has_key?(0x011b))
              result[:y_sampling] = entries[0x011b][0]
            end
            if (entries.has_key?(0x128))
              unit_key = entries[0x128][0]
              if (unit_key == 2)
                result[:sampling_unit] = :inch    
              elsif (unit_key == 3)
                result[:sampling_unit] = :cm    
              end        
            end
            result
          end
          
          def map_image_properties(att_hash)
            result = []
            if (att_hash.has_key?(:size))
              result.push(sprintf(SIZE_TEMPLATE,att_hash[:size]))
            end
            if (att_hash.has_key?(:width))
              result.push(sprintf(WIDTH_TEMPLATE,att_hash[:width]))
            end
            if (att_hash.has_key?(:length))
              result.push(sprintf(LENGTH_TEMPLATE,att_hash[:length]))
            end
            if (att_hash.has_key?(:x_sampling))
              result.push(sprintf(YSAMPLING_TEMPLATE,att_hash[:x_sampling]))
            end
            if (att_hash.has_key?(:y_sampling))
              result.push(sprintf(YSAMPLING_TEMPLATE,att_hash[:y_sampling]))
            end
            if (att_hash.has_key?(:sampling_unit))
              result.push(UNITS[att_hash[:sampling_unit]]) unless UNITS[att_hash[:sampling_unit]].nil?
            end
            
          end
        end  
    end  
end
