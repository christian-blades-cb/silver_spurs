require 'spec_helper'
require 'logger'

describe SilverSpurs::Asyncifier do
  before :each do
    SilverSpurs::Asyncifier.logger = Logger.new('/dev/null')
  end
  
  describe :timeout do
    it 'defaults to 60 minutes' do
      SilverSpurs::Asyncifier.timeout.should eq 60 * 60
    end    
  end

  describe :logger do
    before :each do
      SilverSpurs::Asyncifier.logger = nil
    end
    
    it 'defaults to STDERR' do
      logger_dbl = double('logger')
      logger_dbl.stub(:level=)
      Logger.should_receive(:new).with(STDERR).and_return logger_dbl

      SilverSpurs::Asyncifier.instance.logger
    end    
  end

  describe :spawn_process do
    before :each do
      SilverSpurs::Asyncifier.instance.stub(:create_directory_tree)
      Process.stub(:spawn)
      File.stub(:open)
      Process.stub(:detach)
    end
    
    it 'creates the directory tree' do
      SilverSpurs::Asyncifier.instance.should_receive(:create_directory_tree)
      SilverSpurs::Asyncifier.spawn_process('foo', 'echo foo')
    end

    it 'spawns the process' do
      Process.should_receive(:spawn)
      SilverSpurs::Asyncifier.spawn_process('foo', 'echo foo')
    end

    it 'writes the pid to the lock file' do
      File.should_receive(:open)
      SilverSpurs::Asyncifier.instance.should_receive(:pid_file_path)
      SilverSpurs::Asyncifier.spawn_process('foo', 'echo foo')
    end

    it 'detaches the process' do
      Process.should_receive(:detach)
      SilverSpurs::Asyncifier.spawn_process('foo', 'echo foo')
    end  
  end
  
  describe :has_lock? do
    context 'when there is no pid file' do
      before :each do
        File.stub(:exists?).and_return false
      end
      
      it 'returns false' do
        SilverSpurs::Asyncifier.has_lock?('foo').should be_false
      end

      it 'checks for the pid file' do
        SilverSpurs::Asyncifier.instance.should_receive(:pid_file_path)
        SilverSpurs::Asyncifier.has_lock?('foo')
      end
    end

    context 'when there is a pid file' do
      before :each do
        File.stub(:exists?).and_return true
        File.stub(:read).and_return '1234'
      end

      it 'checks to see if the process is running' do
        IO.should_receive(:popen).with('ps -o command -p 1234').and_return StringIO.new("1\n2")
        SilverSpurs::Asyncifier.has_lock? '1234'
      end

      context 'when the process is running' do
        before :each do
          IO.stub(:popen).and_return StringIO.new("COMMAND\nknife whatever")
        end

        it 'returns true' do
          SilverSpurs::Asyncifier.has_lock?('1234').should be_true
        end                
      end

      context 'when the process is not running' do
        before :each do
          IO.stub(:popen).and_return StringIO.new("COMMAND")
        end

        it 'returns false' do
          SilverSpurs::Asyncifier.has_lock?('1234').should be_false
        end        
      end      

    end

  end

  describe :success? do
    before :each do
      SilverSpurs::Asyncifier.instance.stub(:success_file_path).and_return 'success_file'
    end
    
    it 'checks for a success file' do      
      File.should_receive(:exists?).with('success_file').and_return false
      
      SilverSpurs::Asyncifier.success?('foo')
    end
    
    context 'when the success file does not exist' do
      before :each do
        File.stub(:exists?).and_return false
      end

      it 'returns false' do
        SilverSpurs::Asyncifier.success?('foo').should be_false
      end
    end

    context 'when the success file exists' do
      before :each do
        SilverSpurs::Asyncifier.instance.stub(:pid_file_path).and_return 'pid_file'
        File.stub(:exists?).with('success_file').and_return true
      end
      
      it 'checks to see if the pid file exists' do
        File.should_receive(:exists?).twice.and_return(true, false)
        SilverSpurs::Asyncifier.success? 'foo'
      end

      context 'when the pid file exists' do
        before :each do
          File.stub(:exists?).and_return(true, true)
        end

        it 'checks the modified time of the success and pid file' do
          File.should_receive(:mtime).twice.and_return(Time.now)
          SilverSpurs::Asyncifier.success? 'foo'
        end

        context 'when the success file is younger than the pid file' do
          before :each do
            File.stub(:mtime).and_return(Time.new(2013), Time.new(2012))
          end

          it 'should return true' do
            SilverSpurs::Asyncifier.success?('foo').should be_true
          end
        end

        context 'when the pid file is younger than the success file' do
          before :each do
            File.stub(:mtime).and_return(Time.new(2012), Time.new(2013))
          end

          it 'should return false' do
            SilverSpurs::Asyncifier.success?('foo').should be_false
          end          
        end
                
      end
            
    end
          
  end

  describe :get_log do
    before :each do
      SilverSpurs::Asyncifier.instance.stub(:log_file_path).and_return 'log_file'
    end
    
    it 'checks to see if the log file exists' do
      File.should_receive(:exists?).and_return false
      SilverSpurs::Asyncifier.get_log 'foo'
    end

    context 'when the log file exists' do
      before :each do
        File.stub(:exists?).and_return true
      end

      it 'reads the log' do
        File.stub(:read).and_return 'logs are cool'
        SilverSpurs::Asyncifier.get_log('foo').should eq 'logs are cool'
      end      
    end

    context 'when the log file does not exist' do
      before :each do
        File.stub(:exists?).and_return false
      end

      it 'returns nil' do
        SilverSpurs::Asyncifier.get_log('foo').should be_nil
      end
    end
    
  end

  describe :reap_orphaned_lock do
    before :each do
      SilverSpurs::Asyncifier.instance.stub(:pid_file_path).and_return 'pid_file'
    end
    
    it 'checks to see if the process is active' do
      SilverSpurs::Asyncifier.instance.should_receive(:has_lock?).and_return true
      SilverSpurs::Asyncifier.reap_orphaned_lock 'foo'
    end

    context 'when the process is still active' do
      before :each do
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return true
      end

      it 'should not try to delete the lock' do
        File.should_not_receive(:delete)
        SilverSpurs::Asyncifier.reap_orphaned_lock 'foo'
      end
    end

    context 'when the process is not active' do
      before :each do
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return false
        SilverSpurs::Asyncifier.instance.stub(:pid_file_path).and_return 'pid_file'
      end

      it 'should delete the lock file' do
        File.should_receive(:delete).with('pid_file')
        SilverSpurs::Asyncifier.reap_orphaned_lock 'foo'
      end
    end
    
  end

  describe :reap_process do
    before :each do
      SilverSpurs::Asyncifier.instance.stub(:sleep)
      SilverSpurs::Asyncifier.instance.stub(:reap_orphaned_lock)
      SilverSpurs::Asyncifier.instance.stub(:pid_file_path).and_return 'pid_file'
    end
    
    it 'checks to see if the process is active' do
      SilverSpurs::Asyncifier.instance.should_receive(:has_lock?).and_return false
      SilverSpurs::Asyncifier.reap_process 'foo'
    end

    it 'reaps the lock file' do
      SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return false
      SilverSpurs::Asyncifier.instance.should_receive(:reap_orphaned_lock)
      SilverSpurs::Asyncifier.reap_process 'foo'
    end

    context 'when the process is active' do
      before :each do
        File.stub(:read).and_return '1234'
        Process.stub(:kill)
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return true
      end

      it 'kills the process' do
        Process.should_receive(:kill)
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return(true, false)
        SilverSpurs::Asyncifier.reap_process 'foo'
      end

      it 'checks to see if the process really died' do
        SilverSpurs::Asyncifier.instance.should_receive(:has_lock?).twice.and_return(true, false)
        SilverSpurs::Asyncifier.reap_process 'foo'
      end      

      context 'when the process dies when asked nicely' do
        before :each do
          SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return(true, false)
        end

        it 'just walks away' do
          Process.should_receive(:kill).once
          SilverSpurs::Asyncifier.reap_process 'foo'
        end
      end
      
      context "when the process doesn't die after being asked nicely" do
        before :each do
          SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return(true, true)          
        end
        
        it 'kills the process with fire' do
          Process.should_receive(:kill).twice
          SilverSpurs::Asyncifier.reap_process 'foo'
        end
      end
      
    end

    context 'if the process is inactive' do
      before :each do
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return false        
      end

      it 'skips to reaping the lock file' do
        File.should_not_receive(:read)
        Process.should_not_receive(:kill)
        
        SilverSpurs::Asyncifier.instance.should_receive(:reap_orphaned_lock)
        
        SilverSpurs::Asyncifier.reap_process 'foo'
      end      
    end
    
  end
  
  describe :reap_old_process do
    before :each do
      SilverSpurs::Asyncifier.instance.stub(:pid_file_path).and_return 'pid_file'
    end
    
    it 'checks if the process is active' do
      SilverSpurs::Asyncifier.instance.should_receive(:has_lock?).and_return false
      SilverSpurs::Asyncifier.reap_old_process 'foo'
    end

    context 'when the process is active' do
      before :each do
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return true
      end

      context 'when the process is beyond the timeout window' do
        before :each do
          Time.stub(:now).and_return Time.new(2013)
          SilverSpurs::Asyncifier.instance.stub(:timeout).and_return 100
          File.stub(:mtime).and_return Time.new(2013) - 101          
        end
        
        it 'reaps the process' do
          SilverSpurs::Asyncifier.instance.should_receive(:reap_process)
          SilverSpurs::Asyncifier.reap_old_process 'foo'
        end        
      end

      context 'when the process is within the timeout window' do
        before :each do
          Time.stub(:now).and_return Time.new(2013)
          SilverSpurs::Asyncifier.instance.stub(:timeout).and_return 100
          File.stub(:mtime).and_return Time.new(2013) - 99          
        end
        
        it 'does not reap the process' do
          SilverSpurs::Asyncifier.instance.should_not_receive(:reap_process)
          SilverSpurs::Asyncifier.reap_old_process 'foo'
        end        
      end
      
    end

    context 'when the process is not active' do
      before :each do
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return false
      end

      it 'does not attempt to reap the process' do
        SilverSpurs::Asyncifier.instance.should_not_receive :reap_process
        SilverSpurs::Asyncifier.reap_old_process 'foo'
      end
    end
    
  end
  
  describe :exists? do
    context 'when the process is active' do
      before :each do
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return true
      end
      
      it 'returns true' do
        SilverSpurs::Asyncifier.exists?('foo').should be_true
      end
      
    end

    context 'when the process is not active' do
      before :each do
        SilverSpurs::Asyncifier.instance.stub(:has_lock?).and_return false
        SilverSpurs::Asyncifier.instance.stub(:log_file_path).and_return 'log_file'
      end

      context 'if the log file exists' do
        before :each do
          File.stub(:exists?).and_return true
        end

        it 'returns true' do
          SilverSpurs::Asyncifier.exists?('foo').should be_true
        end          
      end

      context 'if the log file does not exist' do
        before :each do
          File.stub(:exists?).and_return false
        end

        it 'returns false' do
          SilverSpurs::Asyncifier.exists?('foo').should be_false
        end
      end
      
    end
    
  end
  
  describe :log_file_path do
    it 'builds a path in the base directory' do
      SilverSpurs::Asyncifier.instance.should_receive(:base_path).and_return 'base_path'
      File.should_receive(:join)
      SilverSpurs::Asyncifier.instance.send(:log_file_path, 'foo')
    end

    it 'returns a file name' do
      SilverSpurs::Asyncifier.instance.send(:log_file_path, 'foo').should be_a_kind_of(String)
    end
  end

  describe :success_file_path do
    it 'builds a path in the base directory' do
      SilverSpurs::Asyncifier.instance.should_receive(:base_path).and_return 'base_path'
      File.should_receive(:join)
      SilverSpurs::Asyncifier.instance.send(:success_file_path, 'foo')
    end

    it 'returns a file name' do
      SilverSpurs::Asyncifier.instance.send(:success_file_path, 'foo').should be_a_kind_of(String)
    end
  end

  describe :pid_file_path do
    it 'builds a path in the base directory' do
      SilverSpurs::Asyncifier.instance.should_receive(:base_path).and_return 'base_path'
      File.should_receive(:join)
      SilverSpurs::Asyncifier.instance.send(:pid_file_path, 'foo')
    end

    it 'returns a file name' do
      SilverSpurs::Asyncifier.instance.send(:pid_file_path, 'foo').should be_a_kind_of(String)
    end
  end

  describe :create_directory_tree do
    it 'checks to see if the base path already exists' do
      Dir.should_receive(:exists?).at_least(:once).and_return true
      SilverSpurs::Asyncifier.instance.send(:create_directory_tree)        
    end

    context 'if the base path already exists' do
      before :each do
        Dir.stub(:exists?).and_return true
      end
      
      it 'does not create the base directory' do
        Dir.should_not_receive(:mkdir)
        SilverSpurs::Asyncifier.instance.send(:create_directory_tree)
      end
    end

    context 'if the base path does not exist' do
      before :each do
        Dir.stub(:exists?).and_return(false, true)
      end
      
      it 'creates the base directory' do
        Dir.should_receive(:mkdir)
        SilverSpurs::Asyncifier.instance.send(:create_directory_tree)
      end
    end

    context 'if a directory exists' do
      before :each do
        Dir.stub(:exists?).and_return true
      end
      
      it 'does not create the directory' do
        Dir.should_not_receive(:mkdir)
        SilverSpurs::Asyncifier.instance.send(:create_directory_tree)
      end        
    end

    context 'if a directory does not exist' do
      before :each do
        Dir.stub(:exists?).and_return(true, false)
      end
      
      it 'creates the directory' do
        Dir.should_receive(:mkdir).exactly(3).times
        SilverSpurs::Asyncifier.instance.send(:create_directory_tree)
      end
    end
    
  end
  
end
