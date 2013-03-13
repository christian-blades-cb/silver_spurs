require 'rest-client'
require 'addressable/uri'
require 'json'
require 'silver_spurs/knife_interface'
require 'silver_spurs/client/exceptions'

module SilverSpurs
  class Client
    def initialize(host_url, options={})
      @host_url = host_url
    end

    def bootstrap(ip, node_name, options = {})
      params = extract_extra_params(options).merge({:node_name => node_name})
      payload = parameterize_hash params
      headers = {:accept => :json, :content_type=> 'application/x-www-form-urlencoded'}

      response = spur_host["bootstrap/#{ip}"].put(payload, headers)
      throw ClientException("unexpected response", response) unless response.code == 201

      JSON.parse response.body
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
      RestClient::Resource.new(@host_url, :timeout => 15 * 60)
    end
            
  end
end
