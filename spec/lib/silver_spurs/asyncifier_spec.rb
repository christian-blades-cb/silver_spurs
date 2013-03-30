require 'spec_helper'
require 'logger'

describe SilverSpurs::Asyncifier do

  describe 'timeout' do
    it 'defaults to 60 minutes' do
      SilverSpurs::Asyncifier.timeout.should eq 60 * 60
    end    
  end

  describe 'logger' do
    it 'defaults to STDERR' do
      logger_dbl = double('logger')
      logger_dbl.stub(:level=)
      Logger.should_receive(:new).with(STDERR).and_return logger_dbl

      SilverSpurs::Asyncifier.instance.logger
    end    
  end

  describe 'has_lock?' do
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
  
  
end
