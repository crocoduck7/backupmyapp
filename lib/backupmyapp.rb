def require_gem_or_unpacked_gem(name, version = nil)
  unpacked_gems_path = Pathname(__FILE__).dirname.parent + 'gems'
  
  begin
    gem name, version if version
    require name
  rescue Gem::LoadError, MissingSourceFile
    $: << Pathname.glob(unpacked_gems_path + "#{name.gsub('/', '-')}*").last + 'lib'
    require name
  end
end

require 'find'
require 'net/http'
require 'yaml'

require_gem_or_unpacked_gem 'net/ssh'
require_gem_or_unpacked_gem 'net/scp'

class Backupmyapp
  include Timestamps
  include Filesystem
  
  def initialize(init = true)
    @key = File.read(File.join(RAILS_ROOT, "config", "backupmyapp.conf"))
    @server = Backupmyapp::Network.new(@key)
  end
  
  def load_config(action)
    @config = YAML::load @server.init(action, root_directories)
  end
  
  def backup #todo: rescue block
    load_config("backup")
    if @config && @config[:allow]
      Database.backup
      
      files = @server.diff(app_file_structure)
      files = trim_timestamps(app_file_structure) if files == "ALL"

      upload_files(files) if files && files.any?
      @server.finish("backup")
    else
      puts "Backup not allowed (Key invalid, or it is too early to backup)"
    end
  end
  
  def restore #todo: rescue block
    load_config("restore")
    download_files @server.restore
    Database.load
    @server.finish("restore")
  end
  
  def download_files(files)
    Transfer.new(@config, @server).download_collection collect_backup_files(files)
  end
  
  def upload_files(files)
    Transfer.new(@config, @server).upload_collection collect_backup_files(files)
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