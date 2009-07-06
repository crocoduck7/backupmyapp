require 'net/ssh'
require 'net/sftp'
require 'net/scp'
require 'find'
require 'net/http'
require 'yaml'

class Backupmyapp

  def initialize(init = true)
    @key = File.read(File.join(RAILS_ROOT, "config", "backupmyapp.conf"))
    @config = YAML::load post("init") if init
    @removed_files = Array.new
  end
  
  def test
    puts post("test")
  end
  
  def backup
    backup_database
    
    files = post("diff", {'files' => app_file_structure })
    files = trim_timestamps(app_file_structure) if files == "ALL"
    
    upload_files(files) if files.any?
    
    post("finish")
  end
  
  def restore
    download_files post("restore")
    load_database
    post("finish")
  end
  
  def load_database
    MarshalDb.load(Dir.glob("#{RAILS_ROOT}/db/backupmyapp/*").last)
  end
  
  def backup_database
    dump_dir = "#{RAILS_ROOT}/db/backupmyapp/#{short_time(Time.now)}"
    FileUtils.mkdir_p(dump_dir)
    MarshalDb.dump(dump_dir)
  end
  
  def download_files(files)
    backup_files = collect_backup_files(files)

    ssh_session do |scp|
      backup_files.each do |file|
        FileUtils.mkdir_p(file.local_folder)
        puts file.path
        scp.download!(file.remote_path, file.path, :preserve => true) rescue puts("Error occured")
      end
    end
  end
  
  def upload_files(files)
    backup_files = collect_backup_files(files)
    
    ssh_session do |scp|
      backup_files.each do |file|
        puts file.path
        scp.upload!(file.path, file.remote_path, :preserve => true) if File.exists?(file.path)
      end
    end
  end
  
  def ssh_session
    Net::SCP.start(@config[:domain], @config[:user], :password => @config[:password]) do |scp|
      yield(scp)
    end
  end

  def post(uri, options = {})
    ENV['BACKUPMYAPP_HOST'] ? domain = ENV['BACKUPMYAPP_HOST'] : domain = "backupmyapp.com"
    return Net::HTTP.post_form(URI.parse("http://#{domain}/backups/#{uri}/#{@key}"), options).body
  end
  
  def collect_backup_files(files)
    files.split("\n").collect do |file| 
      BackupFile.new file, @config[:backup_path]
    end
  end

  def app_file_structure
    arr = Array.new
    Find.find(RAILS_ROOT) do |path|
      arr << "#{short_time(File.mtime(path))}: #{path.gsub(RAILS_ROOT, '')}" if allowed?(path) && !FileTest.directory?(path)
    end
    
    return arr.join("\n")
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
  
  def trim_timestamps(text)
    text.gsub(/[0-9]+: /, '')
  end
  
  def short_time(date)
    date.utc.strftime("%Y%m%d%H%M%S")
  end
end