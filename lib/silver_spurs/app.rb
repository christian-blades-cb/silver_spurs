require 'sinatra/base'
require 'silver_spurs/knife_interface'
require 'json'


module SilverSpurs
  class App < Sinatra::Base
    
    set :deployment_key, "/etc/chef/deployment_key.pem"
    set :deployment_user, "silverspurs"
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
      return 406, {:bad_params => :node_name} unless node_name =~ settings.node_name_filter

      bootstrap_options = Hash[KnifeInterface.supported_arguments.map do |arg|
                                 value = params[arg]
                                 next if value.nil?
                                 [arg, params[arg]]
                               end]
      
      result = KnifeInterface.bootstrap(params[:ip], node_name, settings.deployment_user, settings.deployment_key, bootstrap_options)
      status_code = result[:exit_code] == 0 ? 201 : 500
      
      return status_code, result.to_json
    end

    def required_vars?(params, requirement_list)
      requirement_list.none? { |required_param| params[required_param].nil? }
    end
        
  end
end
