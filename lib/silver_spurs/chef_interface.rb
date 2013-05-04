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
        ridley.node.execute_command node.public_hostname, command
      else
        node.chef_run
      end
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

  end
end
