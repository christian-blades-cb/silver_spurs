require 'singleton'
require 'forwardable'
require 'ridley'

module SilverSpurs
  class ChefInterface

    def initialize(options)
      @chef_config = options
    end

    def chef_run(node_name, run_list = [])
      node = ridley.node.find(node_name)
      if a.size > 0
        command = "sudo chef-client -o '#{run_list.join(',')}'"
        node.execute_command command
      else
        node.chef_run
      end
    end

    private

    def ridley
      @ridley ||= Ridley.new(@chef_config)
    end

  end
end
