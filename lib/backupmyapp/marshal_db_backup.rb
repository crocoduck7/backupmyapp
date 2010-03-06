require 'active_record/fixtures'

class Backupmyapp
  module MarshalDbBackup
    METADATA_FILE = 'metadata.dump'
 
    def self.dump(directory)
      process do
        MarshalDbBackup::Dump.dump(directory)
      end
    end
 
    def self.load(directory)
      process do
        MarshalDbBackup::Load.load(directory)
      end
    end
 
    def self.process
      old_logger = ActiveRecord::Base.logger
      yield if block_given?
      ActiveRecord::Base.logger = old_logger
    end
 
    def self.zip(zipfile, directory)
      File.delete(zipfile) rescue Errno::ENOENT
 
      Dir.chdir(File.dirname(directory)) do 
        fail "Unable to create #{zipfile}" unless system("zip -qq -r #{zipfile} #{File.basename(directory)}")
      end
 
      clean_work_directory(directory)
    end
 
    def self.unzip(zipfile, directory)
      create_work_directory(directory)
 
      Dir.chdir(File.dirname(directory)) do 
        fail "Unable to unzip #{zipfile}" unless system("unzip -qq #{zipfile}")
      end
    end
 
    class DirectoryError < RuntimeError ; end
 
    def self.clean_work_directory(directory)
      return unless File.exists?(directory)
      raise DirectoryError, "ERROR: #{directory} is not a directory!" unless File.directory?(directory)
 
      FileUtils.rm(Dir.glob("#{directory}/*"), :force => true)
      Dir.rmdir(directory)
    end
 
    def self.create_work_directory(directory)
      clean_work_directory(directory)
      FileUtils.mkdir(directory)
    end
 
    class EncodingException < RuntimeError; end
 
    def self.verify_utf8
      raise "RAILS_ENV is not defined" unless defined?(RAILS_ENV)
 
      unless ActiveRecord::Base.configurations[RAILS_ENV].has_key?('encoding')
        raise EncodingException, "Your database.yml configuration needs to specify encoding"
      end
 
      unless ['unicode', 'utf8'].include?(ActiveRecord::Base.configurations[RAILS_ENV]['encoding'])
        raise EncodingException, "Your database encoding must be utf8 (mysql) or unicode (postgres)"
      end
 
      true
    end
 
    def self.quote_table(table)
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.connection.quote_table_name(table)
    end
  end
 
 
  module MarshalDbBackup::Dump
    def self.dump(directory)
      MarshalDbBackup.create_work_directory(directory)
      dump_metadata(directory)
      dump_data(directory)
    end
 
    def self.dump_data(directory)
      tables.each do |table|
        dump_table_data(directory, table)
      end
    end
 
    def self.dump_table_data(directory, table)
      page = 0
      each_table_page(table) do |records|
        File.open("#{directory}/#{table}.#{page}", 'w') { |f| f.write(Marshal.dump(records)) }
        page += 1
      end
    end
 
    def self.dump_metadata(directory)
      metadata = []
      tables.each do |table|
        metadata << table_metadata(table)
      end
      metadata
 
      File.open("#{directory}/#{MarshalDbBackup::METADATA_FILE}", 'w') { |f| f.write(Marshal.dump(metadata)) }
    end
 
    def self.table_metadata(table)
      metadata = {
        'table' => table,
        'columns' => table_column_names(table),
      }
    end
 
    def self.each_table_page(table, records_per_page = 50000)
      id = table_column_names(table).first
      pages = table_pages(table, records_per_page) - 1
      quoted_table = MarshalDbBackup.quote_table(table)
 
      (0..pages).to_a.each do |page|
        ActiveRecord::Base.connection.reconnect!
        sql = ActiveRecord::Base.connection.add_limit_offset!("SELECT * FROM #{quoted_table} ORDER BY #{id}", { :limit => records_per_page, :offset => records_per_page * page })
        records = ActiveRecord::Base.connection.select_all(sql)
        yield records
      end
    end
 
    def self.table_pages(table, records_per_page)
      total_count = table_record_count(table)
      pages = (total_count.to_f / records_per_page).ceil
      pages
    end
 
    def self.table_record_count(table)
      quoted_table = MarshalDbBackup.quote_table(table)
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.connection.select_one("SELECT COUNT(*) FROM #{quoted_table}").values.first.to_i
    end
 
    def self.table_column_names(table)
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.connection.columns(table).map { |c| c.name }
    end
 
    def self.tables
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.connection.tables.reject { |table| ['schema_info', 'schema_migrations'].include?(table) }
    end
  end
 
 
  module MarshalDbBackup::Load
    def self.load(directory)
      metadata(directory).each do |m|
        truncate_table(m['table'])
        load_table_data(directory, m['table'], m['columns'])
      end
    end
 
    def self.load_table_data(directory, table, columns)
      data_files = table_data_files(directory, table)
      data_files.each do |data_file|
        records = Marshal.load(File.open("#{directory}/#{data_file}", 'r').read)
        load_records(table, columns, records)
      end
      reset_pk_sequence!(table)
    end
 
    def self.metadata(directory)
      Marshal.load(File.open("#{directory}/#{MarshalDbBackup::METADATA_FILE}", 'r').read)
    end
 
    def self.table_data_files(directory, table)
      files = Dir.glob("#{directory}/#{table}.*")
      files.map! { |file| File.basename(file) }
      files.reject! { |file| file == MarshalDbBackup::METADATA_FILE }
      files
    end
 
    def self.truncate_table(table)
      quoted_table = MarshalDbBackup.quote_table(table)
      begin
        ActiveRecord::Base.connection.execute("TRUNCATE #{quoted_table}")
      rescue Exception
        ActiveRecord::Base.connection.execute("DELETE FROM #{quoted_table}")
      end
    end
 
    def self.load_records(table, columns, records)
      quoted_table = MarshalDbBackup.quote_table(table)
      quoted_columns = columns.map { |column| ActiveRecord::Base.connection.quote_column_name(column) }.join(',')
      records.each do |record|
        quoted_values = columns.map { |c| ActiveRecord::Base.connection.quote(record[c]) }.join(',')
        ActiveRecord::Base.connection.execute("INSERT INTO #{quoted_table} (#{quoted_columns}) VALUES (#{quoted_values})")
      end
    end
 
    def self.reset_pk_sequence!(table)
      if ActiveRecord::Base.connection.respond_to?(:reset_pk_sequence!)
        ActiveRecord::Base.connection.reset_pk_sequence!(table)
      end
    end
  end
end