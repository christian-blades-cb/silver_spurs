require 'rest-client'
require 'silver_spurs/client/exceptions'

module SilverSpurs
  class BootstrapRun
    def initialize(async_url, options={})
      @async_url = async_url
      @timeout = options[:timeout] || 2 * 60
    end

    def status
      response = RestClient.head @async_url, &method(:no_exception_for_550)
      
      case response.code
      when 201
        :success
      when 202
        :processing
      when 550
        :failed
      when 404
        throw ClientException.new("the server doesn't know anything about this knife run", response)
      else
        throw ClientException.new("unexpected response", response)
      end
    end

    def log
      response = RestClient.get @async_url, &method(:no_exception_for_550)
      
      case response.code
      when 201, 202, 550
        response.body
      when 404
        throw ClientException.new("the server doesn't know anything about this knife run", response)
      else
        throw ClientException.new("unexpected response", response)
      end
    end

    private
    def no_exception_for_550(response, origin, orig_result, &block)
      if response.code == 550
        response
      else
        response.return! &block
      end
    end
        
  end
end


    
    
