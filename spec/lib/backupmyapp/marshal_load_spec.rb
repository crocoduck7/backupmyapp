require File.dirname(__FILE__) + '/../../spec_helper'

MarshalDb = Backupmyapp::MarshalDbBackup
describe MarshalDb::Load do
	before do
  	ActiveRecord::Base.stub!(:configurations).and_return(mock('configurations'))
  	ActiveRecord::Base.stub!(:connection).and_return(mock('connection'))
  	
		ActiveRecord::Base.connection.stub!(:tables).and_return([ 'mytable' ])
		ActiveRecord::Base.connection.stub!(:columns).with('mytable').and_return([ mock('a',:name => 'a'), mock('b', :name => 'b') ])
		ActiveRecord::Base.connection.stub!(:select_one).and_return({"count"=>"2"})
		ActiveRecord::Base.connection.stub!(:select_all).and_return([ { 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 } ])
		MarshalDb.stub!(:quote_table).with('mytable').and_return('mytable')
	end
 
	before(:each) do
		@io = StringIO.new
	end
 
	it "should truncate the table" do
		ActiveRecord::Base.connection.stub!(:execute).with("TRUNCATE mytable").and_return(true)
		ActiveRecord::Base.connection.should_not_receive(:execute).with("DELETE FROM mytable")
		MarshalDb::Load.truncate_table('mytable')
	end
 
	it "should delete the table if truncate throws an exception" do
		ActiveRecord::Base.connection.should_receive(:execute).with("TRUNCATE mytable").and_raise()
		ActiveRecord::Base.connection.should_receive(:execute).with("DELETE FROM mytable").and_return(true)
		MarshalDb::Load.truncate_table('mytable')
	end
 
	it "should return a list of files for a table in a directory" do
		Dir.stub!(:glob).with("test/mytable.*").and_return(['mytable.0', 'mytable.1'])
		MarshalDb::Load.table_data_files('test', 'mytable').should == ['mytable.0', 'mytable.1']
	end
 
	it "should skip the metadata.dat file" do
		Dir.stub!(:glob).with("test/metadata.*").and_return(['metadata.0', 'metadata.1', 'metadata.dump'])
		MarshalDb::Load.table_data_files('test', 'metadata').should == ['metadata.0', 'metadata.1']
	end
 
	it "should insert records into a table" do
		ActiveRecord::Base.connection.stub!(:quote_column_name).with('a').and_return('a')
		ActiveRecord::Base.connection.stub!(:quote_column_name).with('b').and_return('b')
		ActiveRecord::Base.connection.stub!(:quote).with(1).and_return("'1'")
		ActiveRecord::Base.connection.stub!(:quote).with(2).and_return("'2'")
		ActiveRecord::Base.connection.stub!(:quote).with(3).and_return("'3'")
		ActiveRecord::Base.connection.stub!(:quote).with(4).and_return("'4'")
		ActiveRecord::Base.connection.should_receive(:execute).with("INSERT INTO mytable (a,b) VALUES ('1','2')")
		ActiveRecord::Base.connection.should_receive(:execute).with("INSERT INTO mytable (a,b) VALUES ('3','4')")
 
		MarshalDb::Load.load_records('mytable', ['a', 'b'], [{'a'=>1,'b'=>2}, {'a'=>3,'b'=>4}])
	end
 
	it "should call Marshal.load on every data file for a table" do
		@io.write(Marshal.dump([{'a'=>0,'b'=>1}]))
		@io.rewind
		File.stub!(:open).with('test/mytable.0', 'r').and_return(@io)
 
		MarshalDb::Load.stub!(:table_data_files).with('test', 'mytable').and_return(['mytable.0'])
		MarshalDb::Load.should_receive(:load_records).with('mytable', ['a', 'b'], [{'a'=>0,'b'=>1}])
		MarshalDb::Load.should_receive(:reset_pk_sequence!).with('mytable')
		MarshalDb::Load.load_table_data('test', 'mytable', ['a', 'b'])
	end
 
	it "should iterate through each table in the metadata and truncate the table and load the data" do
		MarshalDb::Load.should_receive(:metadata).with('test').and_return([{'table' => 'mytable', 'columns' => ['a','b']}])
		MarshalDb::Load.should_receive(:truncate_table).with('mytable')
		MarshalDb::Load.should_receive(:load_table_data).with('test', 'mytable', ['a', 'b'])
 
		MarshalDb::Load.load('test')
	end
 
	it "should reset pk sequence if the connection adapter is postgres" do
		ActiveRecord::Base.connection.should_receive(:respond_to?).with(:reset_pk_sequence!).and_return(true)
		ActiveRecord::Base.connection.should_receive(:reset_pk_sequence!).with('mytable')
		MarshalDb::Load.reset_pk_sequence!('mytable')
    end
 
	it "should not call reset pk sequence for other adapters" do
		ActiveRecord::Base.connection.should_receive(:respond_to?).with(:reset_pk_sequence!).and_return(false)
		ActiveRecord::Base.connection.should_not_receive(:reset_pk_sequence!)
		MarshalDb::Load.reset_pk_sequence!('mytable')
	end
end