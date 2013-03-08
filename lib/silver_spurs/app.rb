require 'sinatra/base'
require 'json'

module SilverSpurs
  
  class App < Sinatra::Base
    
    set :deployment_key, "/etc/chef/deployment_key.pem"
    set :deployment_user, "silverspurs"
    
    get '/' do
      %q| We're up and running, cowboy |
    end

    get '/settings' do
      Hash[ [:deployment_key, :deployment_user].map {|key| [key, settings.send(key)]} ].to_json
    end
    
  end

end
