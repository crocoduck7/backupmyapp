require File.dirname(__FILE__) + '/../../spec_helper'

Timestamps = Backupmyapp::Timestamps
describe Timestamps do
  include Timestamps
  
  it "should correctly return file name on trim timestamps" do
    res = trim_timestamps "20090914130202 1319 /vendor/rails/railties/lib/rails_generator/spec.rb\n20090914130202 1692 /vendor/rails/railties/lib/rails_generator.rb"
    res.should == "/vendor/rails/railties/lib/rails_generator/spec.rb\n/vendor/rails/railties/lib/rails_generator.rb"
  end
  
  it "should correctly return short time" do
    time = Time.now
    short_time(time).should == time.utc.strftime("%Y%m%d%H%M%S")
  end
  
  it "should correctly return short mtime" do
    path = File.join(RAILS_ROOT, 'tmp', 'test_file')
    file = File.open(path, 'w') {|f| f.write("test") }
    short_mtime(path).should == short_time(File.mtime(path))
  end
end