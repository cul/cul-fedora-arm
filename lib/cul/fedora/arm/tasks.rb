require 'base64'
require 'net/http'
require 'net/https'
require 'soap/wsdlDriver'
module Cul
  module Fedora
    module Arm
      module Tasks
        APIM = "/fedora/services/management"
        class Task
          def response
            @response
          end
          def initialize()
            super()
            @apim = nil
            @args = {}
          end
          def post(connector)
            if (@apim.nil?)
              raise "Missing APIM SOAPAction name"
            end
            if (@args.empty?)
              raise "No soap arguments"    
            end
            @response = connector.apim_call(@apim, @args) unless (@apim.nil? or @args.empty?)
            @response
          end
        end # Task
        class PurgeTask < Task
          def initialize(pid)
            super()
            @apim = :purgeObject
            @args = {:pid=>pid,:force=>'false',:logMessage=>'purging test objects'}
          end
        end

        class ModifyDatastreamState < Task
          def initialize(pid, dsID, dsState, logMessage)
            super()
            @apim = :setDatastreamState
            @args = { :pid=>pid, :dsState=>dsState, :dsID=>dsID, :logMessage=>logMessage }
          end
        end

        class ObjectXML < Task
          def initialize(pid)
            super()
            @apim = :getObjectXML
            @args = { :pid=>pid }
          end
        end

        class ModifyObject < Task
          def initialize(pid, state, label, ownerId, logMessage)
            super()
            @apim = :modifyObject
            @args = { :pid=>pid, :state=>state, :label=>label, :ownerId=>ownerId, :logMessage=>logMessage }
          end
        end

        class ReservePidsTask < Task
          def initialize(numPids, namespace="demo")
            super()
            @apim = :getNextPID
            @numPids = numPids
            @namespace = namespace
            @args = {:numPIDs=>numPids,:pidNamespace=>namespace}
          end
        end
        class InsertTask < Task
          def initialize()
            super()
            @apim = :ingest
          end
          def post(driver)
            response = super(driver)
            @pid = @response[:pid]
            response
          end
        end
        class InsertFoxmlTask < InsertTask
          def initialize(data)
            super()
            @args[:logMessage] = 'Batch update'
            @args[:format] = 'info:fedora/fedora-system:FOXML-1.1'
            @args[:objectXML] = data
          end
        end
        class UpdateTask < Task
          def initialize(pid)
            super()
            @pid = pid
          end
        end
        class UpdateXmlDatastreamTask < UpdateTask
          def initialize(pid,dsId,dsLabel,dsMIME,formatURI,data)
            super(pid)
            @apim = :modifyDatastreamByValue
            @dsId = dsId
            @inlineData = data
            @args[:pid] = pid
            @args[:dsID] = dsId
            @args[:dsLabel] = dsLabel
            @args[:MIMEType] = dsMIME
            @args[:formatURI] = formatURI
            @args[:dsContent] = data
            @args[:altIDs] = []
            @args[:checksumType] = 'DISABLED'
            @args[:checksum] = 'none'
            @args[:logMessage] = 'Batch update'
            @args[:force] = 'false'
          end
        end
        class UpdateMODSTask < UpdateXmlDatastreamTask
          def initialize(pid,data)
            super(pid,"CONTENT","MODS Desciptive Metadata","text/xml","http://www.loc.gov/mods/v3",data)
          end
        end
        class UpdateDCTask < UpdateXmlDatastreamTask
          def initialize(pid,data)
            super(pid,"DC","Dublin Core Metadata","text/xml","http://www.openarchives.org/OAI/2.0/oai_dc/",data)
          end
        end
      end
    end
  end
end
if __FILE__ == $0
  # TODO Generated stub
end