require 'spec_helper'
require 'ridley'

describe SilverSpurs::ChefInterface do
  
  describe :chef_run do

    before :each do
      @chef_i = SilverSpurs::ChefInterface.new({})
      @ridley = double('ridley')
      @node_resource = double('node_resource')
      @node_obj = double('node_obj')

      @chef_i.stub(:ridley).and_return @ridley
      @ridley.stub(:node).and_return @node_resource
    end    
    
    it 'finds a node and then launches a chef run' do
      @chef_i.should_receive(:find_node).and_return @node_obj
      @node_obj.should_receive(:chef_run)

      @chef_i.chef_run 'node'
    end
    
    context 'with a run list' do
      before :each do
        @chef_i.stub(:find_node).and_return @node_obj
      end
      
      after :each do
        @chef_i.chef_run 'node_name', ['recipe[one]', 'recipe[two]']
      end
      
      it 'should call execute off of the node resource' do
        @node_obj.stub(:public_hostname).and_return 'hostname'
        @node_resource.should_receive(:execute_command)
      end

      it 'should pass in the host name from the node object' do
        @node_obj.should_receive(:public_hostname).and_return 'hostname'
        @node_resource.should_receive(:execute_command).with('hostname', anything)
      end

      it 'should pass in the run list as a comma-seperated string' do
        @node_obj.stub(:public_hostname).and_return 'hostname'
        @node_resource.should_receive(:execute_command).with(anything, %r{'recipe\[one\],recipe\[two\]'})
      end      
    end

    context 'without a run list' do
      after :each do
        @chef_i.chef_run 'node_name'
      end
      
      before :each do
        @chef_i.stub(:find_node).and_return @node_obj
      end
      
      it 'should call chef_run off of the node object' do
        @node_obj.should_receive :chef_run
      end
    end    
      
  end

  describe :find_node do
    
    before :each do
      @chef_i = SilverSpurs::ChefInterface.new({})
      @ridley = double('ridley')
      @node_resource = double('node_resource')

      @chef_i.stub(:ridley).and_return @ridley
      @ridley.stub(:node).and_return @node_resource
    end

    def call_find_node
      @chef_i.send(:find_node, 'node_name')
    end
    
    it 'asks ridley for the node' do
      @node_resource.should_receive(:find).with('node_name').and_return double('node_obj')
      call_find_node
    end
    
    context 'when node exists' do
      before :each do
        @node_obj = double('node_obj')
        @node_resource.stub(:find).and_return @node_obj
      end
      
      it 'should return the node' do
        call_find_node.should eq @node_obj
      end              
    end
    
    context 'when node does not exist' do
      before :each do 
        @node_resource.stub(:find).and_return nil
      end
      
      it 'should throw an error' do
        expect { call_find_node }.to raise_error
      end      
    end
    
  end

  describe :ridley do
    before :each do
      @chef_i = SilverSpurs::ChefInterface.new({})
    end
    
    def call_ridley
      @chef_i.send :ridley
    end
    
    context 'when @ridley has not been initialized' do
      it 'creates a new Ridley instance' do
        Ridley.should_receive(:new)
        call_ridley
      end
    end

    context 'when @ridley has been initialized' do
      it 're-uses the old ridley' do
        Ridley.should_receive(:new).once.and_return double('ridley')
        call_ridley
        call_ridley
      end
    end
        
  end
       
end
