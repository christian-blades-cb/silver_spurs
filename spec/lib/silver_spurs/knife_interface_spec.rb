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

  describe 'supported_arguments' do
    
    it 'includes all of the keys form BOOTSTRAP_ARGS_MAP' do
      SilverSpurs::KnifeInterface::BOOTSTRAP_ARGS_MAP.each do |k,v|
        SilverSpurs::KnifeInterface.supported_arguments.should include k
      end
    end
    
  end

  describe 'bootstrap_command' do

    it 'expands the arguments into a "knife bootstrap -FLAG VALUE HOST" pattern' do
      ip = '1.2.3.4'
      node_name = 'noodles'
      user = 'user'
      key = 'key'
      options = {:distro => 'suse', :run_list => 'recipe[world_one]'}
      expected = "knife bootstrap --no-host-key-verify -i '#{key}' -x '#{user}' -N '#{node_name}' -d 'suse' -r 'recipe[world_one]' #{ip}"
      SilverSpurs::KnifeInterface.bootstrap_command(ip, node_name, user, key, options).should eq expected
    end

  end
  
  
end

  
