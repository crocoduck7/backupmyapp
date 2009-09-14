require File.dirname(__FILE__) + '/../spec_helper'

describe Backupmyapp do
  before(:each) do
    @key = "08435fb3aa4f884cf6c27a56970c16cb"
    File.stub!(:read).and_return(@key)
    
    path = File.join(RAILS_ROOT, "config", "backupmyapp.conf")
    File.should_receive(:exists?).with(path).and_return(true)
    
    @options = {
        :backup_path => "/backup/path",
        :user => "user",
        :password => "password",
        :domain => "backupmyapp.com",
        :ignore => [".git"],
        :allow => ["app", "public", "/tmp"]
      }
  end
  
  class TestHttp
    def init
    end
  end
  
  describe "Initialize method" do
    it "should read key from file" do
      @backuper = Backupmyapp.new
      @backuper.instance_eval("@key").should == "08435fb3aa4f884cf6c27a56970c16cb"
    end
  end
  
#   describe "Load config methods" do
#     before(:each) do
#       @backuper = Backupmyapp.new
#       @backuper.stub!(:root_directories).and_return("app public")
#     end
#     
#     it "should load config for backup method" do
# 
#       @backuper.load_config("backup")
#       @backuper.instance_eval("@config").should == @options
#     end
#     
#     it "should load config for restore method" do
#       @backuper.should_receive(:post).with("init/restore", {"directories" => "app public"}).and_return(@options.to_yaml)
#       @backuper.load_config("restore")
#       @backuper.instance_eval("@config").should == @options
#     end
#   end
#   
#   describe "Test method" do
#     it "Should send test request to home server" do
#       @backuper = Backupmyapp.new
#       @backuper.should_receive(:load_config).with("test")
#       @backuper.should_receive(:post).with("test").and_return(@http_example)
#       @backuper.should_receive(:puts).with(@http_example)
#       @backuper.test
#     end
#   end
#   
#   describe "Database methods" do
#     before(:each) do
#       @backuper = Backupmyapp.new
#     end
#     
#     it "should load database from last DB backup" do
#       MarshalDb.should_receive(:load).with(Dir.glob("#{RAILS_ROOT}/db/backupmyapp/*").last)
#       @backuper.load_database
#     end
#     
#     it "should backup database to specified folder" do
#       FileUtils.stub!(:rm_r)
#       FileUtils.stub!(:mkdir_p)
#       MarshalDb.should_receive(:dump).with("#{RAILS_ROOT}/db/backupmyapp/#{short_time(Time.now)}")
#       @backuper.backup_database
#     end
#     
#     it "should remove DB dump folder if it exists" do
#       File.stub!(:exists?).and_return(true)
#       FileUtils.stub!(:mkdir_p)
#       MarshalDb.stub!(:dump)
#       FileUtils.should_receive(:rm_r).with("#{RAILS_ROOT}/db/backupmyapp/")
#       @backuper.backup_database
#     end
#     
#     it "should create DB dump folder" do
#       File.stub!(:rm_r)
#       FileUtils.stub!(:mkdir_p)
#       MarshalDb.stub!(:dump)
#       FileUtils.should_receive(:mkdir_p).with("#{RAILS_ROOT}/db/backupmyapp/#{short_time(Time.now)}")
#       @backuper.backup_database
#     end
#   end
#   
#   describe "SSH Session" do
#     it "should open ssh session to specified server" do
#       @backuper = Backupmyapp.new
#       
#       expect_load_config
#       Net::SCP.should_receive(:start).with(@options[:domain], @options[:user], :password => @options[:password])
#       @backuper.load_config("backup")
#       @backuper.ssh_session
#     end
#   end
#   
#   describe "Collect backup files method" do
#     it "should mass assign BackupFile objects" do
#       @backuper = Backupmyapp.new
#     
#       files = "app/1.rb\napp/2.rb"
#       collection = files.split("\n").collect do |f|
#         BackupFile.new f, @options[:backup_path]
#       end
#       
#       files.split("\n").each_with_index do |f, index|
#         BackupFile.should_receive(:new).with(f, @options[:backup_path]).and_return(collection[index])
#       end
#       
#       expect_load_config
#       @backuper.load_config("backup")
#       @backuper.collect_backup_files(files).should == collection
#     end
#   end
#   
#   describe "Directory methods" do
#     before(:each) do
#       @backuper = Backupmyapp.new
#     end
#     
#     it "should return file structure in correct format" do
#       res = create_test_files
#       assign_config
#       @backuper.list_dir(RAILS_ROOT).should.should == res
#     end
#     
#     it "should return correct values when directory is ignored" do
#       res = create_test_files
#       @options[:ignore] << "/tmp/dir3"
#       assign_config
#       
#       trimmed_res = []
#       res.each do |r|
#         trimmed_path = r.gsub(/^[0-9 ]+/, '')
#         trimmed_res << r unless trimmed_path.match("\/tmp\/dir3")
#       end
#       
#       @backuper.list_dir(RAILS_ROOT).should.should == trimmed_res
#     end
#     
#     it "should correctly return app file structure" do
#       assign_config
#       test_files = create_test_files
#       @backuper.should_receive(:list_dir).with(RAILS_ROOT).and_return(test_files)
#       @backuper.app_file_structure.should == test_files.join("\n")
#     end
#     
#     it "should correctly trim text" do
#       @backuper.trim_timestamps("20090818180746 4 /tmp/dir/1").should == "/tmp/dir/1"
#     end
#     
#     it "should correctly return short time" do
#       @backuper.short_time(Time.now).should == Time.now.utc.strftime("%Y%m%d%H%M%S")
#     end
#   end
#   
#   describe "Backup method" do
#     before(:each) do
#       @backuper = Backupmyapp.new
#       MarshalDb.stub!(:dump)
#       MarshalDb.stub!(:load)
#       @backuper.stub!("post")
#     end
#     
#     it "should load backup config" do
#       YAML.should_receive(:load).and_return(@options)
#       @backuper.stub!("puts")
#       @backuper.stub!("post").and_return("dir1")
#       @backuper.backup
#     end
#     
#     it "should backup database" do
#       YAML.should_receive(:load).and_return(@options)
#       @backuper.stub!("puts")
#       @backuper.stub!("post").and_return("dir1")
#       @backuper.should_receive("backup_database")
#       @backuper.backup
#     end
#     
#     it "should upload files" do
#       YAML.should_receive(:load).and_return(@options)
#       @backuper.stub!("puts")
#       @backuper.stub!("post").and_return("dir1")
#       @backuper.should_receive("upload_files").with("dir1")
#       @backuper.backup
#     end
#   end
#   
#   describe "Restore method" do
#     before(:each) do
#       @backuper = Backupmyapp.new
#       MarshalDb.stub!(:dump)
#       MarshalDb.stub!(:load)
#       @backuper.stub!("post").and_return("file1")
#       @backuper.stub!("puts")
#     end
#     
#     it "should load restore config" do
#       @backuper.should_receive("load_config").with("restore")
#       @backuper.restore
#     end
#     
#     it "should download files" do
#       @backuper.should_receive("download_files").with("file1")
#       @backuper.restore
#     end
#   end
# 
#   describe "Download files" do
#     before(:each) do
#       @backuper = Backupmyapp.new
#       assign_config
#       
#       Net::SCP.stub!(:start)
#     end
#     
#     it "should start ssh session" do
#       @backuper.should_receive(:ssh_session)
#       @backuper.download_files("file1")
#     end
#     
#     it "should collect backup files" do
#       @backuper.should_receive(:collect_backup_files).with("file1")
#       @backuper.download_files("file1")
#     end
#     
#     it "should upload files" do
#       scp = TestScp.new
#       Net::SCP.stub!(:start).and_return(scp)
#       file = BackupFile.new("file1", @options[:backup_path])
#       @backuper.download_files("file1")
#     end
#   end
#   
#   
#   def expect_load_config
#     @backuper.stub!(:root_directories).and_return("app public")
#     @backuper.should_receive(:post).with("init/backup", {"directories" => "app public"}).and_return(@options.to_yaml)
#   end
#   
#   def assign_config
#     expect_load_config
#     @backuper.load_config("backup")
#   end
#   
#   def create_test_files
#     files = "dir/
# dir/1
# dir/2
# dir/3/
# dir/3/file1
# dir2/
# dir2/file1
# dir2/file2
# dir3/
# dir3/file1
# dir3/file2
# dir4/
# "
# 
#     FileUtils.rm_rf File.join(RAILS_ROOT, "tmp")
#     FileUtils.mkdir_p File.join(RAILS_ROOT, "tmp")
#     
#     results = []
#     files.split("\n").each do |f|
#       path = File.join(RAILS_ROOT, "tmp", f)
#       
#       if f.match(/.+\/$/)
#         FileUtils.mkdir_p path
#       else
#         File.open(path, 'w') {|f| f.write("test") }
#         results << "#{short_time(File.mtime(path).utc)} #{File.size(path)} #{path.gsub(RAILS_ROOT, '')}"        
#       end
#     end
#     
#     return results
#   end
#   
#   def short_time(date)
#     date.utc.strftime("%Y%m%d%H%M%S")
#   end
#   
#   class TestScp
#     def initialize
#     end
#   end
end