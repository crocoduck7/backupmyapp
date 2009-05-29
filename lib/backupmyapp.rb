require 'net/ssh'
require 'net/sftp'
require 'find'
require 'net/http'
require 'yaml'

class Backupmyapp

  def initialize
    @key = File.read(File.join(RAILS_ROOT, "config", "backupmyapp.conf"))
    @config = YAML::load post("init")
  end
  
  def make_backup
    dump_dir = "#{RAILS_ROOT}/db/backupmyapp/#{short_time(Time.now)}"
    FileUtils.mkdir_p(dump_dir)
    MarshalDb.dump(dump_dir)
    
    files = post("diff", {'files' => app_file_structure })
    files = trim_timestamps(app_file_structure) if files == "ALL"
    
    upload_files(files) if files.any?
    
    post("finish")
  end
  
  def upload_files(files)
    backup_files = files.split("\n").collect do |file| 
      BackupFile.new file, @config[:backup_path]
    end
    
    Net::SSH.start(@config[:domain], @config[:user], :password => @config[:password]) do |ssh|
      backup_files.each do |file|
        ssh.exec!("mkdir -p #{file.remote_folder}")
        puts file.path
        File.exists?(file.path) ? ssh.sftp.upload!(file.path, file.remote_path) : ssh.sftp.remove!(file.remote_path)
      end
    end
  end

  def post(uri, options = {})
    Net::HTTP.post_form(URI.parse("http://backupmyapp.local/backups/#{uri}/#{@key}"), options).body
  end

  def app_file_structure
    arr = Array.new
    Find.find(RAILS_ROOT) do |path|
      arr << "#{short_time(File.mtime(path))}: #{path.gsub(RAILS_ROOT, '')}" if allowed?(path) && FileTest.file?(path)
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