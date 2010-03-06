require 'find'
require 'net/http'
require 'yaml'

class Backupmyapp
  include Timestamps
  include Filesystem
  
  def initialize(init = true)
    path = File.join(RAILS_ROOT, "config", "backupmyapp.conf")
    if File.exists?(path)
      @key = File.read(path)
      @server = Network.new(@key)
    else
      Error.no_key
    end
  end
  
  def load_config(action)
    @config = YAML::load @server.init(action, root_directories)
    Error.backup_not_allowed unless @config && @config[:allow]
  end
  
  def backup
    load_config("backup")
    begin
      Database.backup
    rescue => exception
      @server.error("backup", exception.backtrace.join("\n"))
    end
    
    begin
      files = @server.diff(app_file_structure)
      files = trim_timestamps(app_file_structure) if files == "ALL"
      upload_files(files) if files && files.any?
    rescue => exception
      @server.error("backup", exception.backtrace.join("\n"))
    end
    @server.finish("backup")
  end
  
  def restore
    begin
      load_config("restore")
      download_files @server.restore
      Database.load
    rescue
      @server.error("restore", $!)
    end
    @server.finish("restore")
  end
  
  def download_files(files)
    @server.download_collection collect_backup_files(files)
  end
  
  def upload_files(files)
    @server.upload_collection collect_backup_files(files)
  end
  
  def test
    load_config("test")
    puts @server.test
  end

  def collect_backup_files(files)
    files.split("\n").collect { |file| BackupFile.new file, @config[:backup_path] }
  end

  def allowed?(path)
    allow = false
    relative_path = path.gsub(RAILS_ROOT, '')

    @config[:allow].each do |allow_folder|
      allow = true if relative_path.match("^(#{Regexp.escape(allow_folder)})")
    end

    @config[:ignore].each do |ignore_folder|
      allow = false if relative_path.match("^(#{Regexp.escape(ignore_folder)})")
    end

    return allow
  end
end