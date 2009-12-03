class Backupmyapp
  class Database
    def self.load
      Backupmyapp::MarshalDbBackup.load(Dir.glob("#{RAILS_ROOT}/db/backupmyapp/*").last)
    end

    def self.backup
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      dump_dir = "#{RAILS_ROOT}/tmp/backupmyapp/#{timestamp}"
      FileUtils.rm_r("#{RAILS_ROOT}/tmp/backupmyapp/") if File.exists?("#{RAILS_ROOT}/tmp/backupmyapp/")
      FileUtils.mkdir_p(dump_dir)
      Backupmyapp::MarshalDbBackup.dump(dump_dir)
    end
  end
end