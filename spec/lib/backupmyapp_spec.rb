require File.dirname(__FILE__) + '/../spec_helper'

describe Backupmyapp do
  before(:each) do
    system("echo '08435fb3aa4f884cf6c27a56970c16cb' > #{RAILS_ROOT}/config/backupmyapp.conf")
  end
  
  after(:each) do
    system("rm #{RAILS_ROOT}/config/backupmyapp.conf")
  end
  
  describe "Initialize method" do
    it "should read key from file" do
      @backuper = Backupmyapp.new
      @backuper.instance_eval("@key").should == "08435fb3aa4f884cf6c27a56970c16cb\n"
    end
    
    # it "should send request to backupmyapp.com" do
    #   Net::HTTP.post_form.stub!(:body).and_return("
    #     
    #   ")
    # end
  end
end