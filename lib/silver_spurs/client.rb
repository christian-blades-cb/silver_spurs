require 'rest-client'
require 'addressable/uri'
require 'json'
require 'silver_spurs/knife_interface'
require 'silver_spurs/client/exceptions'
require 'silver_spurs/client/bootstrap_run'

module SilverSpurs
  class Client
    def initialize(host_url, options={})
      @host_url = host_url
      @timeout = options[:timeout] || 2 * 60
    end

    def start_bootstrap(ip, node_name, options = {})
      params = extract_extra_params(options).merge({:node_name => node_name})
      payload = parameterize_hash params
      headers = {:accept => :json, :content_type=> 'application/x-www-form-urlencoded'}

      response = spur_host["bootstrap/#{ip}"].put(payload, headers) do |response, &block|
        if response.code == 303
          response
        else
          response.return! &block
        end
      end
      
      throw ClientException.new("unexpected response", response) unless response.code == 303

      BootstrapRun.new(response.headers[:location], :timeout => @timeout)
    end

    private
    
    def parameterize_hash(param_hash)
      uri = Addressable::URI.new
      uri.query_values = param_hash
      uri.query
    end
    
    def extract_extra_params(options)
      supported_arguments = KnifeInterface.supported_arguments
      options.select {|k,v| supported_arguments.include? k}  
    end

    def spur_host
      RestClient::Resource.new(@host_url, :timeout => @timeout)
    end
            
  end
end
