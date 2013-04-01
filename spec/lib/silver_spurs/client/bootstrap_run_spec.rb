require 'rest-client'
require 'silver_spurs/client'

describe SilverSpurs::BootstrapRun do
  describe :status do

    it 'should send HEAD requests' do
      response = double('response')
      response.stub(:code).and_return 201
      RestClient.should_receive(:head).and_return response

      bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
      bootstrap.status
    end
        
    context 'when the service returns a 201' do
      before :each do
        response = double('response')
        response.stub(:code).and_return 201
        RestClient.stub(:head).and_return response
      end

      it 'should return :success' do
        bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
        bootstrap.status.should eq :success
      end      
    end

    context 'when the service returns a 202' do
      before :each do
        response = double('response')
        response.stub(:code).and_return 202
        RestClient.stub(:head).and_return response
      end

      it 'should return :processing' do
        bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
        bootstrap.status.should eq :processing
      end      
    end

    context 'when the service returns a 550' do
      before :each do
        response = double('response')
        response.stub(:code).and_return 550
        RestClient.stub(:head).and_return response
      end

      it 'should return :failed' do
        bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
        bootstrap.status.should eq :failed
      end      
    end

    context 'when the service returns a 404' do
      before :each do
        response = double('response')
        response.stub(:code).and_return 404
        RestClient.stub(:head).and_return response
      end

      it 'should throw an exception' do
        bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
        expect {bootstrap.status}.to raise_error
      end      
    end

    context 'when the server responds with an unknown code' do
      before :each do
        response = double('response')
        response.stub(:code).and_return 500
        RestClient.stub(:head).and_return response
      end

      it 'should throw an exception' do
        bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
        expect {bootstrap.status}.to raise_error
      end
    end
    
  end

  describe :log do
    it 'should send GET requests to the service' do
      response = double('response')
      response.stub(:code).and_return 201
      response.stub(:body).and_return 'logslogslogs'
      RestClient.should_receive(:get).and_return response

      bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
      bootstrap.log
    end

    context 'when there is a non-error response' do

      shared_context 'returns the body' do |response_code|
        context "when the service returns #{response_code}" do
          before :each do
            response = double('response')
            response.stub(:body).and_return 'logslogslogs'
            response.stub(:code).and_return response_code
            RestClient.stub(:get).and_return response
          end
          
          it 'should return the body' do 
            bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
            bootstrap.log.should eq 'logslogslogs'
          end
        end
      end

      include_context 'returns the body', 201
      include_context 'returns the body', 202
      include_context 'returns the body', 550
    end

    context 'when there is an error response' do
      shared_context 'throws an exception' do |response_code|
        context "when the service returns #{response_code}" do
          before :each do
            response = double('response')
            response.stub(:code).and_return response_code
            RestClient.stub(:get).and_return response
          end
          
          it 'should throw an exception' do
            bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
            expect {bootstrap.log}.to raise_error
          end
        end
      end

      include_context 'throws an exception', 404
      include_context 'throws an exception', 500
    end
        
  end

  describe :no_exception_for_550 do
    context 'when the response code is 550' do
      it 'should return the response' do
        response = double('response')
        response.stub(:code).and_return 550

        bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
        bootstrap.send(:no_exception_for_550, response, nil, nil).should eq response
      end
    end

    context 'when the response code is something else' do
      it 'should continue normal processing' do
        response = double('response')
        response.stub(:code).and_return 404
        response.should_receive(:return!)

        bootstrap = SilverSpurs::BootstrapRun.new 'http://localhost'
        bootstrap.send(:no_exception_for_550, response, nil, nil)
      end
    end
        
  end
end
