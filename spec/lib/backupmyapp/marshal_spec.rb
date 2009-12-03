require File.dirname(__FILE__) + '/../../spec_helper'
MarshalDb = Backupmyapp::MarshalDbBackup
describe MarshalDb do
  before do
    # ActiveRecord::Base = mock('ActiveRecord::Base', :null_object => true)
  	ActiveRecord::Base.stub!(:configurations).and_return(mock('configurations'))
  	ActiveRecord::Base.stub!(:connection).and_return(mock('connection'))
  	ActiveRecord::Base.connection.stub!(:tables).and_return([ 'mytable', 'schema_info', 'schema_migrations' ])
  	ActiveRecord::Base.connection.stub!(:columns).with('mytable').and_return([ mock('a',:name => 'a'), mock('b', :name => 'b') ])
  	ActiveRecord::Base.connection.stub!(:select_one).and_return({"count"=>"2"})
  	ActiveRecord::Base.connection.stub!(:select_all).and_return([ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ])
  end

  before do
  	@io = StringIO.new
  	MarshalDb.stub!(:process).and_yield
  end

  it "creates the work directory to dump our files into" do
  	MarshalDb.should_receive(:clean_work_directory).with("rails_root/db/marshal_db")
  	FileUtils.should_receive(:mkdir).with("rails_root/db/marshal_db")
  	MarshalDb.create_work_directory("rails_root/db/marshal_db")
  end

  it "cleans out and removes the work directory" do
  	File.stub!(:directory?).with("rails_root/db/marshal_db").and_return(true)
  	File.stub!(:exists?).with("rails_root/db/marshal_db").and_return(true)
  	Dir.stub!(:glob).with("rails_root/db/marshal_db/*").and_return(%w{file1 file2 file3})
  	FileUtils.should_receive(:rm).with(%w{file1 file2 file3}, :force => true)
  	Dir.should_receive(:rmdir).with("rails_root/db/marshal_db")

  	MarshalDb.clean_work_directory("rails_root/db/marshal_db")
  end

  it "verifies that the connection is encoded with unicode or utf8" do
  	@config = { 'encoding' => 'utf8' }
  	ActiveRecord::Base.configurations.stub!(:[]).with('test').and_return(@config)
  	lambda { MarshalDb.verify_utf8 }.should_not raise_error(MarshalDb::EncodingException)
  end

  it "raises an exception if encoding is not set" do
  	@config = { }
  	ActiveRecord::Base.configurations.stub!(:[]).with('test').and_return(@config)
  	lambda { MarshalDb.verify_utf8 }.should raise_error(MarshalDb::EncodingException)
  end

  it "raises an exception if encoding is not utf8 or unicode" do
  	@config = { 'encoding' => 'latin1' }
  	ActiveRecord::Base.configurations.stub!(:[]).with('test').and_return(@config)
  	lambda { MarshalDb.verify_utf8 }.should raise_error(MarshalDb::EncodingException)
  end

  it "quotes the table name" do
  	ActiveRecord::Base.connection.should_receive(:quote_table_name).with('values').and_return('`values`')
  	MarshalDb.quote_table('values').should == '`values`'
  end
end