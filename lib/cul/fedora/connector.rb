# coding: utf-8
module Cul
  module Fedora
    class Connector
      attr_reader :config
      
      def self.parse(environments)
        connectors = {}
        
        environments.each_pair do |environment, config|
          connectors[environment] = Connector.new(config)
        end 
        
        connectors
      end
      
      def initialize(config)
        @config = config
      end
      
      def rest_interface()
        http = Net::HTTP.start(config_for(:rest, :host),config_for(:rest, :port))
        yield http
        http.finish()
      end
      
      def rest_location()
        url_builder(:rest, "")
      end
      
      def protocol_for(interface)
        config_for(interface.to_s,"ssl") == true ? "https" : "http"
      end
      
      def config_for(interface, value)
        (@config[interface.to_s] && @config[interface.to_s][value.to_s]) || @config[value.to_s]
      end
      
      def url_builder(interface, url)
        "#{protocol_for(interface)}://#{config_for(interface,:host)}:#{config_for(interface,:port)}/#{url}"
      end
      
      def apim_interface()
        wsdl = url_builder(:admin, "fedora/wsdl?api=API-M")
        driver = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
        
        if config_for(:admin, :ssl_verify)
          raise "SSL verification not currently supported. Please specify ssl_verify: false"
        else
          driver.options['protocol.http.ssl_config.verify_mode'] = OpenSSL::SSL::VERIFY_NONE
        end
        
        driver.options["protocol.http.basic_auth"] << [url_builder(:admin,"fedora/services/management"), config_for(:admin,:user), config_for(:admin,:password)]
        
        driver
      end
      
      def apim_call(method, *args)
        options = args.extract_options!
        apim_interface.method(method).call(options)
      end
      
    end
  end
end