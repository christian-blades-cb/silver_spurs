# SilverSpurs [![Build Status](https://travis-ci.org/christian-blades-cb/silver_spurs.png?branch=master)](https://travis-ci.org/christian-blades-cb/silver_spurs)

RESTful Chef bootstrapping

Instead of using a CLI to kick off bootstrapping, hit an API endpoint and let the service do it for you. 

## Installation

Install chef and set up knife on the machine (refer to the [chef docs](http://docs.opscode.com))

Add this line to your application's Gemfile:

    gem 'silver_spurs'

Create a config.ru:

    require 'bundler'
    Bundler.setup
    
    require 'silver_spurs'
    
    # SilverSpurs::App.deployment_key = '/opt/deployment_key.pem'
    # SilverSpurs::App.deployment_user = 'deployer'
    # SilverSpurs::App.node_name_filter = /\w{3,10}/
    # SilverSpurs::Asyncifier.base_path = '/opt/silver_spurs'
    
    run SilverSpurs::App    
    
And then execute:

    $ bundle
    $ rackup

## Usage

### Kick off a bootstrap

    $ curl -X PUT -i -d node_name=machineotron http://localhost/bootstrap/10.0.1.2
    
The redirect will point to the query URL for the bootstrap run. Since these runs tend to take several minutes, this is preferable to a long-running HTTP request.

Further GET requests to this endpoint will return a log of the run in progress. HEAD requests will return just the status code.

### Status codes

* 406 - Missing a required parameter
* 404 - Unknown endpoint or resource
* 201 - Run completed successfully
* 202 - Run in progress
* 550 - Run ended in failure

## Using the client

Add this line to the application's Gemfile:

    gem 'silver_spurs'

Sample application

    require 'silver_spurs/client'
    
    silver = SilverSpurs::Client.new('http://localhost')
    bootstrap = silver.start_bootstrap('10.0.1.2', 'machineotron')
    while bootstrap.status == :pending do
      sleep 10
    end
    puts bootstrap.log

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Add you some tests
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
