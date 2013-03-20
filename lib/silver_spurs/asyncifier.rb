require 'singleton'
require 'forwardable'

module SilverSpurs
  class Asyncifier
    include Singleton
    extend SingleForwardable

    attr_writer :base_path, :timeout
    def_delegators :instance, :has_lock?, :base_path, :base_path=, :timeout=, :timeout, :spawn_process, :has_lock?, :success?, :get_log, :reap_lock_if_done, :reap_process, :reap_process_if_old
    
    def timeout
      @timeout ||= 60 * 60
    end
          
    def base_path
      @base_path ||= './silver_spurs_async'
    end

    def spawn_process(process_name, command)
      create_directory_tree
      logged_command = "#{command} > #{log_file_path process_name} && touch #{success_file_path process_name}"
      pid = Process.spawn logged_command
      File.open(pid_file_path(process_name), 'wb') { |f| f.write pid }
      Process.detach pid
    end
        
    def has_lock?(process_name)
      return false unless File.exists? pid_file_path(process_name)

      pid = File.read(pid_file_path(process_name)).to_i
      /knife/ =~ `ps -o command -p #{pid}`
    end

    def success?(process_name)
      return false unless File.exists? success_file_path(process_name)
      return true unless File.exists? pid_file_path(process_name)      
      File.mtime(success_file_path(process_name)) > File.mtime(pid_file_path(process_name))
    end  

    def get_log(process_name)
      return nil unless File.exists? log_file_path(process_name)
      File.read log_file_path(process_name)
    end

    def reap_lock_if_done(process_name)
      unless has_lock? process_name
        File.delete pid_file_path(process_name)
      end
    end

    def reap_process(process_name)
      if has_lock? process_name
        pid = File.read(pid_file_path(process_name)).to_i
        Process.kill 'KILL', pid
        sleep 1
        Process.kill('TERM', pid) if has_lock? process_name
      end
      reap_lock_if_done process_name
    end

    def reap_process_if_old(process_name)
      if has_lock? process_name
        launch_time = File.mtime pid_file_path(process_name)
        reap_process process_name if Time.now - launch_time > timeout
      end
    end
    
    private

    def log_file_path(process_name)
      filename = "#{process_name}.log"
      File.join base_path, 'status', filename
    end
        
    def success_file_path(process_name)
      filename = "#{process_name}.success"
      File.join base_path, 'status', filename
    end
          
    def pid_file_path(process_name)
      filename = "#{process_name}.pid"
      File.join base_path, 'lockfiles', filename
    end
    
    def create_directory_tree
      Dir.mkdir base_path unless Dir.exists? base_path
      
      ['logs', 'lockfiles', 'status'].each do |directory|
        path = File.join(base_path, directory)
        Dir.mkdir path unless Dir.exists? path
      end
    end
    
  end
end

    
    
