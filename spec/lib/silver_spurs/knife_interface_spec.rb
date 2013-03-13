require 'spec_helper'

describe SilverSpurs::KnifeInterface do

  describe "expand_bootstrap_options" do
    it "expands :identity_file" do
      args = {:identity_file => 'IDENTITY_FILE'}
      expected = %q{-i 'IDENTITY_FILE'}
      
      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it "expands :ssh_user" do
      args = {:ssh_user => 'SSH_USER'}
      expected = %q{-x 'SSH_USER'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :node_name' do
      args = {:node_name => 'NODE_NAME'}
      expected = %q{-N 'NODE_NAME'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :distro' do
      args = {:distro => 'DISTRO'}
      expected = %q{-d 'DISTRO'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :bootstrap_version' do
      args = {:bootstrap_version => 'BOOTSTRAP_VERSION'}
      expected = %q{--bootstrap-version 'BOOTSTRAP_VERSION'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :bootstrap_proxy' do
      args = {:bootstrap_proxy => 'BOOTSTRAP_PROXY'}
      expected = %q{--bootstrap-proxy 'BOOTSTRAP_PROXY'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :gateway' do
      args = {:gateway => 'GATEWAY'}
      expected = %q{-G 'GATEWAY'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :json_attributes' do
      args = {:json_attributes => 'JSON_ATTRIBUTES'}
      expected = %q{-j 'JSON_ATTRIBUTES'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :ssh_port' do
      args = {:ssh_port => 'SSH_PORT'}
      expected = %q{-p 'SSH_PORT'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :ssh_password' do
      args = {:ssh_password => 'SSH_PASSWORD'}
      expected = %q{--ssh-password 'SSH_PASSWORD'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end

    it 'expands :run_list' do
      args = {:run_list => 'RUN_LIST1,RUN_LIST2'}
      expected = %q{-r 'RUN_LIST1,RUN_LIST2'}

      SilverSpurs::KnifeInterface.expand_bootstrap_args(args).should eq [expected]
    end
    
  end
end


  
