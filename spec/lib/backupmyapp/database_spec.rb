require File.dirname(__FILE__) + '/../../spec_helper'

Database = Backupmyapp::Database
describe Database do
  include Backupmyapp::MarshalDb
  
  MarshalDb = Backupmyapp::MarshalDb
  it "should tell marshal to load db on self.load" do
    dir = "#{RAILS_ROOT}/db/backupmyapp/test"
    FileUtils.mkdir_p dir
    MarshalDb.should_receive(:load).with(dir)
    Database.load
  end
  
  describe "Backup" do
    it "should remove database backup folder" do
      FileUtils.mkdir_p("#{RAILS_ROOT}/tmp/backupmyapp/")
      FileUtils.should_receive(:rm_r).with("#{RAILS_ROOT}/tmp/backupmyapp/")
      Database.backup
    end
    
    it "should create database backup folder and dump to it" do
      FileUtils.mkdir_p("#{RAILS_ROOT}/db/backupmyapp/")
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      FileUtils.should_receive(:mkdir_p).with("#{RAILS_ROOT}/tmp/backupmyapp/#{timestamp}")
      MarshalDb.should_receive(:dump).with("#{RAILS_ROOT}/tmp/backupmyapp/#{timestamp}")
      Database.backup
    end
  end
end