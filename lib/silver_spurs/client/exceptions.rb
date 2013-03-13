module SilverSpurs
  class ClientException < Exception
    attr_reader :message, :response

    def initialize(message, response=nil)
      @message = message
      @response = response
    end
  end
end

    
