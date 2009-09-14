require File.dirname(__FILE__) + '/../../spec_helper'

Transfer = Backupmyapp::Transfer
describe Transfer do
  before(:each) do
    @scp = TestScp.new
    @http = TestHttp.new
    config = {:domain => '0.0.0.0', :user => "guest", :password => "password"}
    Net::SCP.should_receive(:start).with(config[:domain], config[:user], :password => config[:password]).and_return(@scp)
    @transfer = Transfer.new(config, @http)
    @transfer.stub!(:puts)
    
    @files = []

    5.times do
      @files << Backupmyapp::BackupFile.new("test1", "test2")
    end
  end
  
  class TestScp
  end
  
  class TestHttp
    def upload_error(files)
    end
  end
  
  describe "upload" do
    it "should correctly upload file" do
      file = @files.first
      @scp.should_receive(:upload).with(file.path, file.remote_path, :preserve => true)
      @transfer.upload(file)
    end
    
    it "should correctly upload collection" do
      @transfer.stub!(:retry_failed_uploads)
      
      @files.each do |file|
        @scp.should_receive(:upload).with(file.path, file.remote_path, :preserve => true)
      end
      
      @transfer.upload_collection(@files)
    end
  end
  
  describe "download" do
    it "should correctly download file" do
      file = @files.first
      @scp.should_receive(:download).with(file.remote_path, file.path, :preserve => true)
      @transfer.download(file)
    end
    
    it "should correctly download collection" do
      @transfer.stub!(:retry_failed_uploads)
      
      @files.each do |file|
        @scp.should_receive(:download).with(file.remote_path, file.path, :preserve => true)
      end
      
      @transfer.download_collection(@files)
    end
  end
end