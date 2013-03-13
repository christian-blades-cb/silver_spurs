module SilverSpurs
  class KnifeInterface
    BOOTSTRAP_ARGS_MAP = {
      :identity_file => '-i',
      :ssh_user => '-x',      
      :node_name => '-N',
      :distro => '-d',
      :bootstrap_version => '--bootstrap-version',
      :bootstrap_proxy => '--bootstrap-proxy',
      :gateway => '-G',
      :json_attributes => '-j',
      :ssh_port => '-p',
      :ssh_password => '--ssh-password',
      :run_list => '-r'
    }

    def self.supported_arguments
      BOOTSTRAP_ARGS_MAP.map {|k,v| k}
    end

    def self.expand_bootstrap_args(arguments)
      BOOTSTRAP_ARGS_MAP.map do |arg, flag|
        value = arguments[arg]
        next nil if value.nil?

        "#{flag} '#{value}'"
      end.reject {|arg| arg.nil?}              
    end
        
    def self.bootstrap(ip, node_name, deployment_user, deployment_key, options = {})      
      bootstrap_options = {
        :identity_file => deployment_key,
        :ssh_user => deployment_user,
        :node_name => node_name
      }.merge options

      arguments = expand_bootstrap_args bootstrap_options
      
      strap_r, strap_w = IO.pipe

      knife_pid = spawn('knife', 'bootstrap', *arguments, ip, :err => :out, :out => strap_w)
      
      Process.waitpid(knife_pid)
      exitcode = $?.exitstatus
      
      strap_w.close
      loglines = strap_r.read
      strap_r.close

      {
        :exit_code => exitcode,
        :log_lines => loglines
      }
    end

  end
end
