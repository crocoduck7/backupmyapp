require File.dirname(__FILE__) + '/../../spec_helper'
require 'httpclient'

Network = Backupmyapp::Network
HOST = Network::HOST
describe Network do
  
  describe "Requests" do
    before(:each) do
      stub_net
    end
    
    it "should send correct request" do;
      @net.should_receive(:post).with("#{HOST}/backups/connect/key", {:plugin_version=> Network::PLUGIN_VERSION}).and_return(@http_stub)
      @network.post("connect").should == "response"
    end
    
    it "should send correct reuest with options" do
      options = {"q" => "ruby"}
      @net.should_receive(:post).with("#{HOST}/backups/connect/key", options).and_return(@http_stub)
      @network.post("connect", options)
    end
  end
  
  describe "Additional requests" do
    before(:each) do
      @network = Network.new("key")
    end
    
    it "should send init action" do
      @network.should_receive(:post).with("init/action", {'directories' => "app public"})
      @network.init("action", "app public")
    end
    
    it "should send diff action" do
      @network.should_receive(:post).with("diff", {'files' => "file1\nfile2"})
      @network.diff("file1\nfile2")
    end
    
    it "should send restore action" do
      @network.should_receive(:post).with("restore")
      @network.restore
    end
    
    it "should send test action" do
      @network.should_receive(:post).with("test")
      @network.test
    end
    
    it "should send finish action" do
      @network.should_receive(:post).with("finish/backup")
      @network.finish("backup")
    end
    
    it "should send error with correct text and key" do
      @network.should_receive(:post).with("error", {:hash => "key", :body => "On restore: test error"})
      @network.error("restore", "test error")
    end
    
    describe "Errors" do
      before(:each) do
        @files = []
  
        5.times do
          @files << Backupmyapp::BackupFile.new("test1", "test2")
        end
      end
      
      it "should send upload error" do      
        @network.should_receive(:error).with("Upload", @files.map(&:path).join("\n"))
        @network.upload_error(@files)
      end
    
      it "should send download error" do
        @network.should_receive(:error).with("Download", @files.map(&:path).join("\n"))
        @network.download_error(@files)
      end
    end
  end
  
  describe "Upload/download methods" do
    before(:each) do
      stub_net
      @files = []
      

      5.times do
        @files << Backupmyapp::BackupFile.new("test1", "test2")
      end

      File.stub!(:new).and_return(FileStub.new)
    end
    
    class FileStub
      def mtime
        Time.now
      end
    end

    describe "upload" do
      # it "should correctly upload file" do
      #   file = @files.first
      #   f = File.new(file.path)
      #   params = { 'file' => f, 'mtime' => f.mtime.utc, 'location' => file.relative_path, 'key' => "key" }
      #   
      #   @net.should_receive(:post).with("#{HOST}/files/upload", params)
      #   @network.upload(file)
      # end
      
      it "should correctly upload collection" do
        @network.stub!(:retry_failed_uploads)
      
        @files.each do |file|
          @network.should_receive(:upload).with(file)
        end
      
        @network.upload_collection(@files)
      end
    end

    describe "upload" do
      # it "should correctly upload file" do
      #   file = @files.first
      #   f = File.new(file.path)
      #   params = { 'file' => f, 'mtime' => f.mtime.utc, 'location' => file.relative_path, 'key' => "key" }
      #   
      #   @net.should_receive(:post).with("#{HOST}/files/restore", params)
      #   @network.upload(file)
      # end
      
      it "should correctly upload collection" do
        @network.stub!(:retry_failed_uploads)
      
        @files.each do |file|
          @network.should_receive(:download).with(file)
        end
      
        @network.download_collection(@files)
      end
    end
  end
  
  class HttpStub
    def content
      "response"
    end
  end
  
  def stub_net
    @net = HTTPClient.new      
    HTTPClient.stub!(:new).and_return(@net)
    @network = Network.new("key")
    @http_stub = HttpStub.new
  end
end