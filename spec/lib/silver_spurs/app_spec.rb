require 'spec_helper'
require 'json'

describe SilverSpurs::App do
  include Rack::Test::Methods
  
  def app
    SilverSpurs::App
  end

  describe '/' do
    it "should return 200" do
      get '/'
      last_response.status.should be 200
    end
  end

  describe '/settings' do
    it "should tell us about the deployment_key, deployment_user and node_name_filter" do
      get '/settings'
      settings_hash = JSON.parse last_response.body
      [:deployment_key, :deployment_user, :node_name_filter].each do |setting|
        settings_hash.keys.should include setting.to_s
      end
    end
  end
  
  describe "/bootstrap/:ip" do

    context "when the node is not already being bootstrapped" do
      before :each do
        SilverSpurs::Asyncifier.stub(:has_lock?).and_return false
      end
      
      it "builds a bootstrap command" do
        SilverSpurs::Asyncifier.stub(:spawn_process)
        SilverSpurs::KnifeInterface.should_receive(:bootstrap_command).with('10.0.0.0', 'yourmom', kind_of(String), kind_of(String), kind_of(Hash))

        put '/bootstrap/10.0.0.0', :node_name => 'yourmom'
      end

      it "spawns a knife run" do
        SilverSpurs::Asyncifier.should_receive(:spawn_process).with(kind_of(String), kind_of(String))
        SilverSpurs::KnifeInterface.stub(:bootstrap_command).and_return 'knife bootstrap'

        put '/bootstrap/10.0.0.0', :node_name => 'yourmom'
      end
    end
    
    context "when a node name is not passed in" do
      it "should return a 406 status" do
        put '/bootstrap/10.0.0.0'
        last_response.status.should be 406
      end
    end
        
    context "with bad node name" do
      it "should reject node names with spaces" do
        node_name = "your mom"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should be 406
      end

      it "should reject node names with underscores" do
        node_name = "your_mom"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 406
      end

      it "should reject node names with other chars" do
        node_name = "node[name]*%$"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 406
      end

      it "should reject empty node names" do
        node_name = ""
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 406
      end

      it "should reject node names under 3 chars" do
        node_name = "12"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 406
      end

      it "should reject node names over 15 chars" do
        node_name = "1234567890123456"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 406
      end
    end

    context "with good node name" do
      before(:each) do
        SilverSpurs::Asyncifier.stub(:has_lock?).and_return true
      end
      
      it "should accept node names with dashes" do
        node_name = "your-mom"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 303
      end

      it "should accept one-word node names" do
        node_name = "mom"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 303
      end

      it "should accept node names with numbers" do
        node_name = "mombot-3000"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 303
      end

      it "should accept node names with 15 chars" do
        node_name = "123456789012345"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 303
      end

      it "should accept node names with 3 chars" do
        node_name = "123"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 303
      end
    end
    
  end

  describe '/bootstrap/query/:process_id' do
    
    describe 'HEAD' do
      
      context 'when process does not exist' do
        before :each do
          SilverSpurs::Asyncifier.stub(:exists?).and_return false
        end
                
        it 'should return a 404' do
          head '/bootstrap/query/fake_process'
          last_response.status.should eq 404
        end
      end

      context 'when process is still running' do
        before :each do
          SilverSpurs::Asyncifier.stub(:exists?).and_return true
          SilverSpurs::Asyncifier.stub(:reap_old_process)
          SilverSpurs::Asyncifier.stub(:has_lock?).and_return true
        end

        it 'should return a 202' do
          head '/bootstrap/query/fake_process'
          last_response.status.should eq 202
        end
      end

      context 'when process finished successfully' do
        before :each do
          SilverSpurs::Asyncifier.stub(:exists?).and_return true
          SilverSpurs::Asyncifier.stub(:reap_old_process)
          SilverSpurs::Asyncifier.stub(:has_lock?).and_return false
          SilverSpurs::Asyncifier.stub(:success?).and_return true
        end

        it 'should return a 201' do
          head '/bootstrap/query/fake_process'
          last_response.status.should eq 201
        end
      end

      context 'when process finished in failure' do
        before :each do
          SilverSpurs::Asyncifier.stub(:exists?).and_return true
          SilverSpurs::Asyncifier.stub(:reap_old_process)
          SilverSpurs::Asyncifier.stub(:has_lock?).and_return false
          SilverSpurs::Asyncifier.stub(:success?).and_return false
        end

        it 'should return a 550' do
          head '/bootstrap/query/fake_process'
          last_response.status.should eq 550
        end
      end
      
    end

    describe 'GET' do
      before :each do
        SilverSpurs::Asyncifier.stub(:get_log).and_return "Loggylog"
      end
      
      context 'when process does not exist' do
        before :each do
          SilverSpurs::Asyncifier.stub(:exists?).and_return false
        end
                
        it 'should return a 404' do
          get '/bootstrap/query/fake_process'
          last_response.status.should eq 404
        end

        it 'should not spit out a log' do
          get '/bootstrap/query/fake_process'
          last_response.body.should_not eq 'Loggylog'
        end
        
      end

      context 'when process is still running' do
        before :each do
          SilverSpurs::Asyncifier.stub(:exists?).and_return true
          SilverSpurs::Asyncifier.stub(:reap_old_process)
          SilverSpurs::Asyncifier.stub(:has_lock?).and_return true
        end

        it 'should return a 202' do
          get '/bootstrap/query/fake_process'
          last_response.status.should eq 202
        end

        it 'should spit out a log' do
          get '/bootstrap/query/fake_process'
          last_response.body.should eq 'Loggylog'
        end        
      end

      context 'when process finished successfully' do
        before :each do
          SilverSpurs::Asyncifier.stub(:exists?).and_return true
          SilverSpurs::Asyncifier.stub(:reap_old_process)
          SilverSpurs::Asyncifier.stub(:has_lock?).and_return false
          SilverSpurs::Asyncifier.stub(:success?).and_return true
        end

        it 'should return a 201' do
          get '/bootstrap/query/fake_process'
          last_response.status.should eq 201
        end

        it 'should spit out a log' do
          get '/bootstrap/query/fake_process'
          last_response.body.should eq 'Loggylog'
        end
      end

      context 'when process finished in failure' do
        before :each do
          SilverSpurs::Asyncifier.stub(:exists?).and_return true
          SilverSpurs::Asyncifier.stub(:reap_old_process)
          SilverSpurs::Asyncifier.stub(:has_lock?).and_return false
          SilverSpurs::Asyncifier.stub(:success?).and_return false
        end

        it 'should return a 550' do
          get '/bootstrap/query/fake_process'
          last_response.status.should eq 550
        end

        it 'should spit out a log' do
          get '/bootstrap/query/fake_process'
          last_response.body.should eq 'Loggylog'
        end
      end
      
    end
    
  end

  describe '/kick/:ip' do
    before :each do
      @chef = double('chef')
      SilverSpurs::ChefInterface.stub(:new).and_return @chef
    end

    it 'starts a chef run' do
      @chef.should_receive :chef_run

      post '/kick/node'
    end

    context 'when the node does not exist' do
      it 'should return a 404' do
        @chef.stub(:chef_run).and_raise(SilverSpurs::NodeNotFoundException.new)

        post '/kick/node'
        last_response.status.should eq 404
      end
    end

  end

  describe '/attributes/:ip' do
    before :each do
      @chef = double('chef')
      SilverSpurs::ChefInterface.stub(:new).and_return @chef
    end

    context 'when attributes are supplied' do

      before :each do
        @attributes = {
          :attributes => {
            :thing => 'sloth',
            :things => 'more_sloths'
          }
        }.to_json

        header 'Content-Type', 'application/json'
      end

      it 'updates the attributes on the target node' do
        @chef.should_receive(:update_node_attributes)

        put '/attributes/node', @attributes
        last_response.status.should eq 200
      end

      context 'and the node does not exist' do
        it 'should return a 404' do
          @chef.stub(:update_node_attributes).and_raise(SilverSpurs::NodeNotFoundException.new)

          put '/attributes/node', @attributes
          last_response.status.should eq 404
        end
      end

    end

    context 'when attributes are not supplied' do

      it 'returns a 406 since attributes (required) were not present' do
        put '/attributes/node'
        last_response.status.should eq 406
      end

      context 'and the node does not exist' do
        it 'should still return a 406 due to the missing attributes' do
          put '/attributes/node'
          last_response.status.should eq 406
        end
      end

    end

  end
   
end

    
