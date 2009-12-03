require File.dirname(__FILE__) + '/../../spec_helper'

MarshalDb = Backupmyapp::MarshalDbBackup
describe MarshalDb::Dump do  
	before(:each) do
  	ActiveRecord::Base.stub!(:configurations).and_return(mock('configurations'))
  	ActiveRecord::Base.stub!(:connection).and_return(mock('connection'))
  	
		ActiveRecord::Base.connection.stub!(:tables).and_return([ 'mytable', 'schema_info', 'schema_migrations' ])
		ActiveRecord::Base.connection.stub!(:columns).with('mytable').and_return([ mock('a',:name => 'a'), mock('b', :name => 'b') ])
		ActiveRecord::Base.connection.stub!(:select_one).and_return({"count"=>"2"})
		ActiveRecord::Base.connection.stub!(:select_all).and_return([ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ])
	end
 
	before(:each) do
		@io = StringIO.new
	end
 
	it "should return a list of column names" do
		MarshalDb::Dump.table_column_names('mytable').should == [ 'a', 'b' ]
	end
 
	it "should return a list of tables without the rails schema table" do
		MarshalDb::Dump.tables.should == ['mytable']
	end
 
	it "should return the number of 'pages' in a table" do
		MarshalDb::Dump.stub!(:table_record_count).with('mytable').and_return(20)
		MarshalDb::Dump.table_pages('mytable', 7).should == 3
	end
 
	it "should return the table's metadata" do
		MarshalDb::Dump.table_metadata('mytable').should == { 'table' => 'mytable', 'columns' => ['a', 'b'] }
	end
 
	it "should write out a table's data to a file" do
		File.stub!(:open).with('test/mytable.0', 'w').and_yield(@io)
		MarshalDb::Dump.stub!(:each_table_page).with('mytable').and_yield([ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ])
		MarshalDb::Dump.dump_table_data('test', 'mytable')
		@io.rewind
		@io.read.should == Marshal.dump([ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ])
	end
 
	it "should dump all table data" do
		MarshalDb::Dump.should_receive(:dump_table_data).with('test', 'mytable')
		MarshalDb::Dump.dump_data('test')
	end
 
	it "should create the work directory, dump the metadata and then dump the actual data" do
		MarshalDb.should_receive(:create_work_directory).with('test')
		MarshalDb::Dump.should_receive(:dump_metadata).with('test')
		MarshalDb::Dump.should_receive(:dump_data).with('test')
		MarshalDb::Dump.dump('test')
	end
end