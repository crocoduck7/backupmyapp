require File.dirname(__FILE__) + '/../../spec_helper'
require 'net/http'

Network = Backupmyapp::Network
describe Network do
  
  describe "Requests" do
    before(:each) do
      @network = Network.new("key")
      @net = Net::HTTP.new(Network::BMA_HOST, 80)
      @http_stub = HttpStub.new
      Net::HTTP.should_receive(:new).and_return(@net)
    end
    
    it "should send correct request" do;
      @net.should_receive(:post).with("/backups/connect/key", "").and_return(@http_stub)
      @network.post("connect").should == "response"
    end
    
    it "should send correct reuest with options" do
      options = {"q" => "ruby"}
      params = CGI.escape options.collect {|k, v| "#{k}=#{v}"}.join("&")
      @net.should_receive(:post).with("/backups/connect/key", params).and_return(@http_stub)
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
    
    it "should send error" do
      @network.should_receive(:post).with("error", {:body => "On restore: test error"})
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
  
  class HttpStub
    def body
      "response"
    end
  end
end