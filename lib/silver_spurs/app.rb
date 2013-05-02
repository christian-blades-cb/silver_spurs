require 'sinatra/base'
require 'silver_spurs/knife_interface'
require 'json'
require 'silver_spurs/asyncifier'
require 'silver_spurs/chef_interface'
require 'ridley'

module SilverSpurs
  class App < Sinatra::Base
    
    set :deployment_key, "/etc/chef/deployment_key.pem"
    set :deployment_user, "silverspurs"
    set :chef_config, {
      server_url: 'http://localhost:4000',
      client_name: 'silver_spurs',
      client_key: '/etc/chef/silver_spurs.pem',
      ssh: {
        user: settings.deployment_user,
        keys: [ settings.deployment_key ],
        paranoid: false
      }
    }
    # sane setting for AD subdomain
    set :node_name_filter, /^[-A-Za-z0-9]{3,15}$/
    
    get '/' do
      %q| Ride 'em, cowboy |
    end

    get '/settings' do
      important_settings =
        [
         :deployment_key,
         :deployment_user,
         :node_name_filter
        ]
                                  
      Hash[ important_settings.map {|key| [key, settings.send(key)]} ].to_json
    end

    put '/bootstrap/:ip' do
      required_params = [:node_name]
      unless required_vars? params, required_params
        return 406, {:required_params => required_params}.to_json
      end

      node_name = params[:node_name].strip
      return 406, {:bad_params => :node_name}.to_json unless node_name =~ settings.node_name_filter

      process_name = "knife_bootstrap_#{params[:ip].strip.gsub '.', '_'}"

      unless Asyncifier.has_lock? process_name
        logger.info "Asynchronously spawning knife command. process_name = [#{process_name}]"
        bootstrap_options = Hash[KnifeInterface.supported_arguments.map do |arg|
                                   value = params[arg]
                                   next if value.nil?
                                   [arg, params[arg]]
                                 end]
      
        command = KnifeInterface.bootstrap_command(
                                                   params[:ip],
                                                   node_name,
                                                   settings.deployment_user,
                                                   settings.deployment_key,
                                                   bootstrap_options)
        logger.debug "knife command: #{command}"
        Asyncifier.spawn_process process_name, command
      end
      
      redirect to("/bootstrap/query/#{process_name}"), 303
    end

    head '/bootstrap/query/:process_id' do
      return 404 unless Asyncifier.exists? params[:process_id]
      Asyncifier.reap_old_process params[:process_id]
      return 202 if Asyncifier.has_lock? params[:process_id]
      if Asyncifier.success? params[:process_id]
        return 201
      else
        return 550
      end
    end

    get '/bootstrap/query/:process_id' do
      return 404 unless Asyncifier.exists? params[:process_id]
      Asyncifier.reap_old_process params[:process_id]

      headers 'Content-Type' => 'text/plain'
      body Asyncifier.get_log params[:process_id]
      if Asyncifier.success? params[:process_id]
        status 201
      elsif Asyncifier.has_lock? params[:process_id]
        status 202
      else
        status 550
      end
    end

    post '/kick/:ip' do
      run_list = params[:run]
      chef = ChefInterface.new(settings.chef_config)
      chef.chef_run(params[:ip], run_list).to_json
    end

    def required_vars?(params, requirement_list)
      requirement_list.none? { |required_param| params[required_param].nil? }
    end
    
  end
end
