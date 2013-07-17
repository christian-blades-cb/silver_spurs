require 'rest-client'
require 'silver_spurs/client/exceptions'
require 'erb'

module SilverSpurs
  class ChefOutput

    attr_reader :log, :status

    def initialize(response)
      @status = convert_status response
      @log = prettify_log response
    end

    private

    def convert_status(response)
      failure = (response['exit_code'] == 1) || (response['exit_status'] == 1)
      failure ? :failed : :success
    end

    def prettify_log(response)
      stdout = response['stdout']
      stderr = response['stderr']
      exit_code = response['exit_code'] || response['exit_status']

      template = ERB.new <<-END
Exit Code: <%= exit_code %>
--STDOUT-----------------
<%= stdout %>
--STDERR-----------------
<%= stderr %>
      END
      template.result binding
    end

  end
end