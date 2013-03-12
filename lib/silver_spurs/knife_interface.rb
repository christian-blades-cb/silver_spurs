module SilverSpurs
  class KnifeInterface
    
    def self.bootstrap(ip, node_name, deployment_user, deployment_key)
      puts "doing a thing"
      strap_r, strap_w = IO.pipe
      
      knife_pid = spawn("knife bootstrap -x '#{deployment_user}' -i '#{deployment_key}' -d ubuntu12.04-silver -N #{node_name} #{ip}", :err => :out, :out => strap_w)
      
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
