require 'spec_helper'

describe SilverSpurs::App do
  include Rack::Test::Methods
  
  def app
    SilverSpurs::App
  end
  
  describe "/bootstrap/:ip" do
    
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
            
    end

    context "with good node name" do
      before(:each) do
        SilverSpurs::KnifeInterface.stub(:bootstrap).and_return({:exit_code => 0, :log_lines => "I'm a test!"})
      end
      
      it "should accept node names with dashes" do
        node_name = "your-mom"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        puts last_response.body
        last_response.status.should eq 201
      end

      it "should accept one-word node names" do
        node_name = "mom"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 201
      end

      it "should accept node names with numbers" do
        node_name = "mombot-3000"
        put "/bootstrap/10.0.0.0", :node_name => node_name
        last_response.status.should eq 201
      end
      
    end
        
  end
end

    
