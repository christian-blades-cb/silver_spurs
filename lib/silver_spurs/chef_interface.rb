require 'singleton'
require 'forwardable'
require 'ridley'
require 'silver_spurs/chef_exceptions'

module SilverSpurs
  class ChefInterface

    def initialize(options)
      @chef_config = options
    end

    def chef_run(node_name, run_list = [])
      node = find_node node_name
      if run_list.size > 0
        command = "sudo chef-client -o '#{run_list.join(',')}'"
        ridley.node.execute_command find_hostname(node_name, node), command
      else
        node.chef_run
      end
    end

    def update_node_attributes(node_name, attributes)
      node = find_node node_name
      attributes.each do |attribute_name, value|
        node.set_chef_attribute attribute_name, value
      end
      node.save
    end

    private

    def ridley
      @ridley ||= Ridley.new(@chef_config)
    end

    def find_node(node_name)
      node = ridley.node.find(node_name)
      raise NodeNotFoundException.new unless node
      node
    end

    # Waterfall through the options, use the node name as a last resort
    def find_hostname(node_name, node)
      return node.public_hostname if node.public_hostname
      return node.public_ipv4 if node.public_ipv4
      return node_name
    end
    
  end
end
