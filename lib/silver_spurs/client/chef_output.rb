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
      code = response[0]
      case code
      when 'ok'
        :success
      when 'error'
        :failed
      end
    end

    def prettify_log(response)
      run_info = response[1]
      stdout = run_info['stdout']
      stderr = run_info['stderr']
      exit_code = run_info['exit_code'] || run_info['exit_status']

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
