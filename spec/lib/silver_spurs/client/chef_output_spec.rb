require 'silver_spurs/client/chef_output'

describe SilverSpurs::ChefOutput do
  describe :convert_status do
    before :each do
      @chef_run = SilverSpurs::ChefOutput.new({'stdout' => '', 'stderr' => '', 'exit_code' => 0, 'exit_status' => 0})
    end

    def call_convert_status(response)
      @chef_run.send(:convert_status, response)
    end

    context 'exit code and status = 0' do
      before :each do
        @response = { 'exit_code' => 0, 'exit_status' => 0}
      end

      it "should return :success" do
        call_convert_status(@response).should eq :success
      end
    end

    context 'exit code or status = 1' do
      it "should return :failed" do
        @response = { 'exit_code' => 0, 'exit_status' => 1}
        call_convert_status(@response).should eq :failed
      end

      it "should return :failed" do
        @response = { 'exit_code' => 1, 'exit_status' => 0}
        call_convert_status(@response).should eq :failed
      end
    end

  end

  describe :prettify_log do
    before :each do
      @chef_run = SilverSpurs::ChefOutput.new({'stdout' => '', 'stderr' => '', 'exit_code' => 0, 'exit_status' => 0})
    end

    def call_prettify_log(response)
      @chef_run.send :prettify_log, response
    end

    it 'should output stderr' do
      response = {'stdout' => '', 'stderr' => 'stdERR, son', 'exit_code' => 0, 'exit_status' => 0}
      call_prettify_log(response).should match(/stdERR, son/)
    end

    it 'should output stdout' do
      response = {'stdout' => 'stdOUT, son', 'stderr' => '', 'exit_code' => 0, 'exit_status' => 0}
      call_prettify_log(response).should match(/stdOUT, son/)
    end

    context 'when exit_code and exit_status are present' do
      it 'should prefer exit_code' do
        response = {'stdout' => '', 'stderr' => '', 'exit_code' => 1, 'exit_status' => 2}
        call_prettify_log(response).should match(/Exit Code: 1/)
      end
    end

    context 'when exit_code is not present' do
      it 'should use exit_status' do
        response = {'stdout' => '', 'stderr' => '', 'exit_code' => nil, 'exit_status' => 2}
        call_prettify_log(response).should match(/Exit Code: 2/)
      end
    end

    context 'when exit_status is not present' do
      it 'should use exit_code' do
        response = {'stdout' => '', 'stderr' => '', 'exit_code' => 1, 'exit_status' => nil}
        call_prettify_log(response).should match(/Exit Code: 1/)
      end
    end

    context 'when exit_code and exit_status are not present' do
      it 'should use nil' do
        response = {'stdout' => '', 'stderr' => '', 'exit_code' => nil, 'exit_status' => nil}
        call_prettify_log(response).should match(/Exit Code: /)
      end
    end

  end

end
