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

  def initialize(init = true)
    @key = File.read(File.join(RAILS_ROOT, "config", "backupmyapp.conf"))
  end
  
  def load_config(action)
    @config = YAML::load post("init/#{action}", {'directories' => Dir.glob("#{RAILS_ROOT}/*/").join(" ").gsub(RAILS_ROOT, '')})
  end
  
  def backup
    load_config("backup")
    if @config
      begin
        backup_database

        files = post("diff", {'files' => app_file_structure })
        files = trim_timestamps(app_file_structure) if files == "ALL"
    
        upload_files(files) if files.any?
      rescue
        puts "Error occured: #{$!}"
        post ("error", {:body => "On backup: #{$!}"}) 
      end
      post("finish/backup")
    else
      puts "Backup not allowed now"
    end
  end
  
  def restore
    begin
      load_config("restore")
      download_files post("restore")    
      load_database
    rescue
      puts "Error occured: #{$!}"
      post ("error", {:body => "On restore: #{$!}"})
    end
    post("finish/restore")
  end
  
  def test
    load_config("test")
    puts post("test")
  end
  
  def load_database
    MarshalDb.load(Dir.glob("#{RAILS_ROOT}/db/backupmyapp/*").last)
  end
  
  def backup_database
    dump_dir = "#{RAILS_ROOT}/db/backupmyapp/#{short_time(Time.now)}"
    FileUtils.rm_r("#{RAILS_ROOT}/db/backupmyapp/") if File.exists?("#{RAILS_ROOT}/db/backupmyapp/")
    FileUtils.mkdir_p(dump_dir)
    MarshalDb.dump(dump_dir)
  end
  
  def download_files(files)
    backup_files = collect_backup_files(files)

    ssh_session do |scp|
      backup_files.each do |file|
        FileUtils.mkdir_p(file.local_folder)
        puts file.path
        scp.download!(file.remote_path, file.path, :preserve => true, :verbose => true)
      end
    end
  end
  
  def upload_files(files)
    backup_files = collect_backup_files(files)
    ssh_session do |scp|
      do_files_upload(backup_files, scp)
    end
  end
  
  def do_files_upload(backup_files, scp, try = 1)
    failed_files = []
    puts "Retry to upload No. #{try}"
    
    backup_files.each do |file|
      if File.exists?(file.path)
        puts file.path
        if File.readable?(file.path)
          scp.upload!(file.path, file.remote_path, :preserve => true)
        else
          failed_files << file
        end
      end
    end
    
    if try < 4
      do_files_upload(failed_files, scp, try + 1) if failed_files.any?
    else
      post("error", {:body => "On backup: These files are not readable: #{failed_files.collect {|f| f.path}.join("\n")}"})
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

  def app_file_structure(root = RAILS_ROOT, arr = [])
    return list_dir(RAILS_ROOT).join("\n")
  end

  def list_dir(dir, arr=[])
    Dir.new("#{dir}").each do |file|
      next if file.match(/^\.+/)
      
      path = "#{dir}/#{file}"
      if FileTest.directory?(path)
        list_dir(path, arr)
      else
        arr << "#{short_time(File.mtime(path).utc)}: #{path.gsub(RAILS_ROOT, '')}" if allowed?(path) && File.exists?(path)
      end
    end
    
    return arr
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