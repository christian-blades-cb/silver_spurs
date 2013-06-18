require 'spec_helper'
require 'ridley'

describe SilverSpurs::ChefInterface do
  
  describe :chef_run do

    before :each do
      @chef_i = SilverSpurs::ChefInterface.new({})
      @ridley = double('ridley')
      @node_resource = double('node_resource')
      @node_obj = double('node_obj')
      @node_obj.stub(:public_hostname).and_return 'node_name'

      @chef_i.stub(:ridley).and_return @ridley
      @ridley.stub(:node).and_return @node_resource
    end    
    
    it 'finds a node and then launches a chef run' do
      @chef_i.should_receive(:find_node).and_return @node_obj
      @node_obj.should_receive :chef_run

      @chef_i.chef_run 'node'
    end
    
    context 'with a run list' do
      before :each do
        @chef_i.stub(:find_node).and_return @node_obj
        @node_obj.stub(:merge_data)
        @node_resource.stub(:run)
        @run_list = ['recipe[one]', 'recipe[two]']
      end
      
      after :each do
        @chef_i.chef_run 'node_name', @run_list
      end
      
      it 'should call run off of the node resource' do
        @node_resource.should_receive(:run)
      end

      it 'should pass in the run list to ridley if provided' do
        @node_resource.should_receive(:run)
          .with(kind_of(String), /^(.+)'recipe\[one],recipe\[two]'$/)
      end      
    end

    context 'without a run list' do
      after :each do
        @chef_i.chef_run 'node_name'
      end
      
      before :each do
        @chef_i.stub(:find_node).and_return @node_obj
      end
      
      it 'should call #run off of the node object' do
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

  describe :find_hostname do
    before :each do
      @chef_i = SilverSpurs::ChefInterface.new({})
      @node_resource = double('node_resource')
      @node_name = 'node_name'
      @hostname = 'hostname.domain.tld'
      @ipv4 = '1.1.1.1'
    end
    
    def call_find_hostname(node_name, node)
      @chef_i.send :find_hostname, node_name, node
    end

    context 'when node knows about public_hostname' do
      before :each do
        @node_resource.stub(:public_hostname).and_return @hostname
      end

      context 'and also public_ipv4' do
        before :each do
          @node_resource.stub(:public_ipv4).and_return @ipv4
        end

        it 'returns the public hostname' do
          call_find_hostname(@node_name, @node_resource).should eq @hostname
        end
      end

      context 'but not public_ipv4' do
        before :each do
          @node_resource.stub(:public_ipv4).and_return nil
        end

        it 'returns the public hostname' do
          call_find_hostname(@node_name, @node_resource).should eq @hostname
        end
      end
    end

    context 'when node does not know about public_hostname' do
      before :each do
        @node_resource.stub(:public_hostname).and_return nil
      end

      context 'but does know public_ipv4' do
        before :each do
          @node_resource.stub(:public_ipv4).and_return @ipv4
        end

        it 'returns the public_ipv4' do
          call_find_hostname(@node_name, @node_resource).should eq @ipv4
        end
      end

      context 'and is also ignorant of the public_ipv4' do
        before :each do
          @node_resource.stub(:public_ipv4).and_return nil
        end

        it 'returns the node name' do
          call_find_hostname(@node_name, @node_resource).should eq @node_name
        end
      end
    end
    
  end

  describe :update_node_attributes do

    before :each do
      @chef_i = SilverSpurs::ChefInterface.new({})
      @node_obj = double('node_obj')
    end

    context 'when the target node is found' do
      it 'finds a node then updates its attributes' do
        @chef_i.should_receive(:find_node).and_return @node_obj
        @node_obj.should_receive(:set_chef_attribute).with(kind_of(String), kind_of(String))
        @node_obj.should_receive(:save)

        @chef_i.update_node_attributes 'node', { 'app.program.config' => 'bananas' }
      end
    end

    context 'when the target node is not found' do
      before :each do
        @ridley = double('ridley')
        Ridley.stub(:new).and_return @ridley
        @node_resource = double('node_res')
        @ridley.stub(:node).and_return @node_resource
        @node_resource.stub(:find).and_return nil
      end

      it 'throws an exception when trying to find the target node' do
        expect {
          @chef_i.update_node_attributes('node', { 'app.program.config' => 'bananas' })
        }.to raise_exception SilverSpurs::NodeNotFoundException
      end

      it 'does not try to set or save any node attributes' do
        @node_obj.should_not_receive(:set_chef_attribute).with any_args
        @node_obj.should_not_receive(:save).with any_args

        expect {
          @chef_i.update_node_attributes('node', { 'app.program.config' => 'bananas' })
        }.to raise_exception SilverSpurs::NodeNotFoundException
      end
    end

  end
end
