require 'cul/fedora/image/image'
require 'pathname'
require 'rexml/document'
require 'uri'
module Cul
  module Fedora
    module Arm
AGGREGATOR_FOXML = <<INGEST
﻿<?xml version="1.0" encoding="UTF-8"?>
<foxml:digitalObject PID="{0[pid]}" VERSION="1.1"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
  <foxml:objectProperties>
    <foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="Active"/>
    <foxml:property NAME="info:fedora/fedora-system:def/model#label" VALUE="{0[title_attr]}"/>
    <foxml:property NAME="info:fedora/fedora-system:def/model#ownerId" VALUE="fedoraAdmin"/>
    <foxml:property NAME="info:fedora/fedora-system:def/model#createdDate" VALUE="{0[timestamp]}"/>
    <foxml:property NAME="info:fedora/fedora-system:def/view#lastModifiedDate" VALUE="{0[timestamp]}"/>
  </foxml:objectProperties>
  <foxml:datastream CONTROL_GROUP="X" ID="DC" STATE="A" VERSIONABLE="true">
    <foxml:datastreamVersion CREATED="{0[timestamp]}"
      FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/" ID="DC1.0"
      LABEL="Dublin Core Record for this object" MIMETYPE="text/xml">
      <foxml:xmlContent>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
          <dc:title>{0[title]}</dc:title>
          <dc:creator>BATCH</dc:creator>
          <dc:type>{0[dc_type]}</dc:type>
          <dc:identifier>{0[id]}</dc:identifier>
        </oai_dc:dc>
      </foxml:xmlContent>
    </foxml:datastreamVersion>
  </foxml:datastream>
  <foxml:datastream CONTROL_GROUP="X" ID="RELS-EXT" STATE="A" VERSIONABLE="true">
    <foxml:datastreamVersion CREATED="{0[timestamp]}"
      FORMAT_URI="info:fedora/fedora-system:FedoraRELSExt-1.0" ID="RELS-EXT1.0"
      LABEL="RDF Statements about this object" MIMETYPE="application/rdf+xml">
      <foxml:xmlContent>
        <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#"
                 xmlns:ore="http://www.openarchives.org/ore/terms/"
     xmlns:cul="http://purl.oclc.org/NET/CUL/"
    xmlns:cc="http://creativecommons.org/ns#"
                 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about="info:fedora/{0[pid]}">
            <fedora-model:hasModel rdf:resource="info:fedora/{0[content_model]}"/>
    <rdf:type rdf:resource="http://purl.oclc.org/NET/CUL/Aggregator" />
    <cc:license rdf:resource="info:fedora/{0[license]}" />
    {0[rels]}
          </rdf:Description>
        </rdf:RDF>
      </foxml:xmlContent>
    </foxml:datastreamVersion>
  </foxml:datastream>
</foxml:digitalObject>
INGEST
# >>
METADATA_FOXML = <<INGEST
<?xml version="1.0" encoding="UTF-8"?>
<foxml:digitalObject VERSION="1.1" PID="{0[pid]}" xmlns:foxml="info:fedora/fedora-system:def/foxml#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
  <foxml:objectProperties>
    <foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="A"/>
    <foxml:property NAME="info:fedora/fedora-system:def/model#label" VALUE="{0[title_attr]}"/>
  </foxml:objectProperties>
  <foxml:datastream ID="DC" STATE="A" CONTROL_GROUP="X" VERSIONABLE="true">
    <foxml:datastreamVersion FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/" ID="DC.0" MIMETYPE="text/xml" LABEL="Dublin Core Record for this object" SIZE="488" CREATED="2004-12-10T00:21:58.000Z">
      <foxml:xmlContent>
        <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/">
          <dc:title>{0[title]}</dc:title>
          <dc:creator>BATCH</dc:creator>
          <dc:type>Text</dc:type>
          <dc:format>text/xml</dc:format>
          <dc:publisher>Columbia University Libraries</dc:publisher>
          <dc:identifier>{0[identifier]}</dc:identifier>
          <dc:source>{0[source]}</dc:source>
        </oai_dc:dc>
      </foxml:xmlContent>
    </foxml:datastreamVersion>
  </foxml:datastream>
  <foxml:datastream ID="RELS-EXT" CONTROL_GROUP="X">
    <foxml:datastreamVersion FORMAT_URI="info:fedora/fedora-system:FedoraRELSExt-1.0" 
                             ID="RELS-EXT.0" MIMETYPE="application/rdf+xml" 
                             LABEL="RDF Statements about this object" CREATED="{0[timestamp]}">
      <foxml:xmlContent>
        <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#"
                xmlns:rel="info:fedora/fedora-system:def/relations-external#"
    xmlns:cul="http://purl.oclc.org/NET/CUL/"
    xmlns:cc="http://creativecommons.org/ns#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about="info:fedora/{0[pid]}">
            <fedora-model:hasModel rdf:resource="info:fedora/ldpd:MODSMetadata"/>
    <rdf:type rdf:resource="http://purl.oclc.org/NET/CUL/Metadata" />
            {0[rels]}
          </rdf:Description>
        </rdf:RDF>
      </foxml:xmlContent>
    </foxml:datastreamVersion>
  </foxml:datastream>
  <foxml:datastream CONTROL_GROUP="X" ID="CONTENT" STATE="A" VERSIONABLE="true">
    <foxml:datastreamVersion CREATED="{0[timestamp]}"
      ID="CONTENT.0" LABEL="{0[title_attr]}" MIMETYPE="text/xml">
      <foxml:xmlContent>{0[metadata]}</foxml:xmlContent>
    </foxml:datastreamVersion>
  </foxml:datastream>
</foxml:digitalObject>
INGEST
# >>
RESOURCE_FOXML = <<RESOURCE
<?xml version="1.0" encoding="UTF-8"?>
<foxml:digitalObject PID="{0[pid]}" VERSION="1.1"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
  <foxml:objectProperties>
    <foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="Active"/>
    <foxml:property NAME="info:fedora/fedora-system:def/model#label" VALUE="{0[title_attr]}"/>
    <foxml:property NAME="info:fedora/fedora-system:def/model#ownerId" VALUE="fedoraAdmin"/>
    <foxml:property NAME="info:fedora/fedora-system:def/model#createdDate" VALUE="{0[timestamp]}"/>
    <foxml:property NAME="info:fedora/fedora-system:def/view#lastModifiedDate" VALUE="{0[timestamp]}"/>
  </foxml:objectProperties>
  <foxml:datastream CONTROL_GROUP="X" ID="DC" STATE="A" VERSIONABLE="true">
    <foxml:datastreamVersion CREATED="{0[timestamp]}"
      FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/" ID="DC1.0"
      LABEL="Dublin Core Record for this object" MIMETYPE="text/xml">
      <foxml:xmlContent>
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" >
          <dc:creator>BATCH</dc:creator>
          <dc:publisher>Columbia University Libraries</dc:publisher>
          <dc:type>{0[dc_type]}</dc:type>
          <dc:format>{0[mime]}</dc:format>
          <dc:identifier>{0[pid]}</dc:identifier>
          <dc:source>{0[src]}</dc:source>
        </oai_dc:dc>
      </foxml:xmlContent>
    </foxml:datastreamVersion>
  </foxml:datastream>
  <foxml:datastream CONTROL_GROUP="X" ID="RELS-EXT" STATE="A" VERSIONABLE="true">
    <foxml:datastreamVersion CREATED="{0[timestamp]}"
      FORMAT_URI="info:fedora/fedora-system:FedoraRELSExt-1.0" ID="RELS-EXT1.0"
      LABEL="RDF Statements about this object" MIMETYPE="application/rdf+xml">
      <foxml:xmlContent>
        <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#"
    xmlns:dcmi="http://purl.org/dc/terms/"
    xmlns:si-basic="http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/"
    xmlns:si-assess="http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/ASSESSMENT/"
     xmlns:cul="http://purl.oclc.org/NET/CUL/"
    xmlns:rel="info:fedora/fedora-system:def/relations-external#"
    xmlns:cc="http://creativecommons.org/ns#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about="info:fedora/{0[pid]}">
    <rdf:type rdf:resource="http://purl.oclc.org/NET/CUL/Resource" />
    <fedora-model:hasModel rdf:resource="info:fedora/ldpd:Resource"/>
    {0[rels]}
    <cc:license rdf:resource="info:fedora/{0[license]}" />
  </rdf:Description>
        </rdf:RDF>
      </foxml:xmlContent>
    </foxml:datastreamVersion>
  </foxml:datastream>
  <foxml:datastream CONTROL_GROUP="{0[datastream_type]}" ID="CONTENT" STATE="A" VERSIONABLE="true">
    <foxml:datastreamVersion CREATED="{0[timestamp]}"
      ID="CONTENT.0" LABEL="{0[title_attr]}" MIMETYPE="{0[mime]}">
      <foxml:contentLocation
        REF="{0[source]}" TYPE="INTERNAL_ID"/>
    </foxml:datastreamVersion>
  </foxml:datastream>
</foxml:digitalObject>
RESOURCE
# >>


      class FoxmlBuilder
        include Cul::Fedora::Image
        STATIC_IMAGE_DEFAULTS = {
          :content_model => 'ldpd:StaticImageAggregator',
          :title => 'Image Aggregator',
          :title_attr => 'Image Aggregator',
          :dc_type => 'Image',
        }
        CONTENT_DEFAULTS = {
          :content_model => 'ldpd:ContentAggregator',
          :title => 'Generic Content Aggregator',
          :title_attr => 'Generic Content Aggregator',
          :dc_type => 'InteractiveResource',
        }
        METADATA_DEFAULTS = {
          :content_model => 'ldpd:MODSMetadata',
          :dc_type => 'Text',
          :dc_format => 'text/xml'
        }
        RESOURCE_DEFAULTS = {
          :content_model => 'ldpd:Resource'
        }
        DEFAULTS = {
          :staticimage_aggregator => STATIC_IMAGE_DEFAULTS,
          :content_aggregator => CONTENT_DEFAULTS,
          :metadata => METADATA_DEFAULTS,
          :image_resource => RESOURCE_DEFAULTS,
          :resource => RESOURCE_DEFAULTS
        }
        TEMPLATES = {
          :aggregator => Cul::Fedora::Arm::AGGREGATOR_FOXML,
          :metadata => Cul::Fedora::Arm::METADATA_FOXML,
          :resource => Cul::Fedora::Arm::RESOURCE_FOXML
        }
        METADATA_FOR = "<cul:metadataFor rdf:resource=\"info:fedora/%s\" />"
        MEMBER_OF = "<cul:memberOf rdf:resource=\"info:fedora/%s\" />"
        UTF8_MARKER = "\xEF\xBB\xBF"
        
        def build(value_hash)         
          template_type = value_hash[:template_type]
          model_type = value_hash[:model_type]
          value_default_key = (template_type.downcase + "_" + model_type.downcase).intern
          subs = {}
          if(DEFAULTS.has_key?(value_default_key))
            subs = DEFAULTS[value_default_key].merge(value_hash)
            now  = Time.now
            subs[:timestamp] = now.strftime("%Y-%m-%dT%H:%M:%S.000Z")
            subs[:rels] = build_rels(subs)
          else
            subs = value_hash.merge({:timestamp=>Time.now.strftime("%Y-%m-%dT%H:%M:%S.000Z")})
            subs[:rels] = build_rels(subs)
          end
          if (subs.has_key?(:source))
            subs[:source].strip!
            if(subs[:source].length > 0)
              if (subs[:source].index('http:') != 0)
                if(subs[:model_type].eql?('Metadata'))
                  subs[:metadata] = File.open(subs[:source]){|file| file.read() }
                  subs.merge!(parse_mods(subs[:metadata]))
                end
                realpath = ""
                begin
                  realpath = Pathname.new(subs[:source]).realpath
                rescue
                  realpath = subs[:source]
                end
                subs[:source] = 'file://' + realpath
                subs[:datastream_type] = 'E'
              else
                subs[:datastream_type] = 'M'
              end
            end
          end

          template_key = model_type.downcase.intern
          if(TEMPLATES.has_key?(template_key))
            return sub_values(subs,TEMPLATES[template_key])
          else
            raise "Unknown model type #{value_hash[:model_type]}"
          end
        end
        protected
        
        def parse_mods(data)
          # attempt to assign title/title_attr and identifier
          result = {}
            xml = REXML::Document.new(data)
            element = xml.elements["/mods/titleInfo/title"]
            if (element)
              result[:title] = element.text
              result[:title_attr] = URI.escape(element.text)
            end
            element = xml.elements["/mods/recordInfo/recordIdentifier"]
            if (element)
              result[:identifier] = element.text
            elsif (element = xml.elements["/mods/identifier"])
              result[:identifier] = element.text
            end
          result
        end
        
        def build_rels(value_hash)
          if (value_hash[:target].nil?)
            return ''
          end
          rels = ''
          targets = value_hash[:target].split(';')
          tmp = value_hash[:model_type].downcase.eql?('metadata') ? METADATA_FOR : MEMBER_OF          
          targets.each {|target|
            rels += sprintf(tmp,target)
          }
          if (value_hash[:model_type].eql?('Resource') and not value_hash[:dc_format].index('Image').nil?)
            image_props = analyze_image(value_hash[:source])
            value_hash[:mime] = image_props[:mime] 
            image_rels = map_image_properties(image_props)
            image_rels.each {|rel|
              rels += rel
            }
          end
          rels
        end

        def sub_values(value_hash,template)
            data = template.gsub(/\{0\[(\w+)\]\}/) {|match|
              value_hash[$1.intern]
            }
            data.strip!
            if (data.index(UTF8_MARKER) == 0)
              data.slice!(0...UTF8_MARKER.length)
            end
            data
        end
      end
    end
  end
end