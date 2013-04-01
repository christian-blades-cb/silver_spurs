require 'spec_helper'
require 'silver_spurs/client'

describe SilverSpurs::Client do
  describe :start_bootstrap do
    context 'the service returns a redirect' do
      it 'should return a BootStrapRun' do
        response = double('response')
        response.stub(:code).and_return 303
        response.stub(:headers).and_return({:location => '/bootstrap/query/your_mom'})
        
        request = double('request')
        request.stub(:put).and_return response
        
        resource = double('resource')
        resource.stub(:[]).and_return request

        client = SilverSpurs::Client.new 'http://localhost'
        client.stub(:spur_host).and_return resource
        
        SilverSpurs::BootstrapRun.should_receive(:new)
        
        client.start_bootstrap('10.0.1.2', 'your_mom')
      end
    end

    context 'the service returns something else' do
      it 'should throw an exception' do
        response = double('response')
        response.stub(:code).and_return 404
        response.stub(:headers).and_return({:location => '/bootstrap/query/your_mom'})
        
        request = double('request')
        request.stub(:put).and_return response
        
        resource = double('resource')
        resource.stub(:[]).and_return request

        client = SilverSpurs::Client.new 'http://localhost'
        client.stub(:spur_host).and_return resource
        
        SilverSpurs::BootstrapRun.should_not_receive(:new)
        
        expect {client.start_bootstrap('10.0.1.2', 'your_mom')}.to raise_error
      end
    end
    
  end

  describe :parameterize_hash do
    it 'should turn a hash into qstring params' do
      params = {:hot_dog => :mustard, :hamburger => 'with cheese'}
      expected = 'hamburger=with%20cheese&hot_dog=mustard'

      client = SilverSpurs::Client.new 'http://localhost'
      client.send(:parameterize_hash, params).should eq expected
    end    
  end

  describe :extract_extra_params do
    it 'should query KnifeInterface for which params are supported' do
      SilverSpurs::KnifeInterface.should_receive(:supported_arguments).and_return []

      client = SilverSpurs::Client.new 'http://localhost'
      client.send(:extract_extra_params, {:foo=>:bar})
    end
    
    it 'should filter out params which are not supported by KnifeInterface' do
      SilverSpurs::KnifeInterface.stub(:supported_arguments).and_return [:foo, :bar]

      params = {:foo=>:foo, :bar=>:bar, :hamburger=>:hamburger}
      expected = {:foo=>:foo, :bar=>:bar}
      
      client = SilverSpurs::Client.new 'http://localhost'
      client.send(:extract_extra_params, params).should eq expected
    end
    
  end

  describe :spur_host do
    it 'should return a new rest resource' do
      RestClient::Resource.should_receive(:new)

      client = SilverSpurs::Client.new 'http://localhost'
      client.send(:spur_host)
    end
  end

  describe :dont_redirect_for_303 do
    context 'when the response code is 303' do
      it 'should return the response' do
        response = double('response')
        response.stub(:code).and_return 303

        client = SilverSpurs::Client.new 'http://localhost'
        client.send(:dont_redirect_for_303, response, nil, nil).should eq response
      end      
    end

    context 'when the response code is something else' do
      it 'should continue normal processing' do
        response = double('response')
        response.stub(:code).and_return 404
        response.should_receive(:return!)

        client = SilverSpurs::Client.new 'http://localhost'
        client.send(:dont_redirect_for_303, response, nil, nil)
      end
    end
    
  end
  
end
