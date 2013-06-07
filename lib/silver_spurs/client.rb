require 'rest-client'
require 'addressable/uri'
require 'json'
require 'silver_spurs/knife_interface'
require 'silver_spurs/client/exceptions'
require 'silver_spurs/client/bootstrap_run'
require 'silver_spurs/client/chef_output'

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

      response = gracefully_handle_rest_call do
        spur_host["bootstrap/#{ip}"].put(payload, headers, &method(:dont_redirect_for_303))
      end
      
      throw ClientException.new("unexpected response", response) unless response.code == 303

      BootstrapRun.new(response.headers[:location], :timeout => @timeout)
    end

    def start_chef_run(host_name, runlist = [])
      response = gracefully_handle_rest_call do
        spur_host["kick/#{host_name}"].post :params => { :run => runlist }
      end
      ChefOutput.new JSON.parse(response)
    end

    def set_node_attributes(host_name, attributes = {})
      headers = { :accept => :json, :content_type => 'application/json' }
      gracefully_handle_rest_call do
        spur_host["attributes/#{host_name}"].put({ :attributes => attributes }.to_json, headers)
      end
    end

    private

    def gracefully_handle_rest_call(&rest_call)
      begin
        response = rest_call.call
      rescue RestClient::ResourceNotFound
        raise ClientException.new("the host name was not found", response)
      rescue Exception
        raise ClientException.new("an unanticipated error occured", response)
      end

      response
    end
    
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

    def dont_redirect_for_303(response, origin, orig_result, &block)
      if response.code == 303
        response
      else
        response.return! &block
      end
    end
                
  end
end
