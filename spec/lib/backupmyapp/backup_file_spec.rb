require File.dirname(__FILE__) + '/../../spec_helper'

BackupFile = Backupmyapp::BackupFile
describe BackupFile do
  before(:each) do
    @remote_path = "/home/guest/asdasd"
    @backup_file = BackupFile.new("/public/image.png", @remote_path)
  end
  
  it "should return correct path of file" do 
    @backup_file.path.should == File.join(RAILS_ROOT, "/public/image.png")
  end
  
  it "should return correct remote path of file" do 
    @backup_file.remote_path.should == "#{@remote_path}/public/image.png"
  end
  
  it "should return correct remote folder of file" do
    @backup_file.remote_folder.should == "#{@remote_path}/public/"
  end
  
  it "should return correct remote folder of file" do
    @backup_file.local_folder.should == File.join(RAILS_ROOT, "/public/")
  end
end