namespace :backupmyapp do 
  
  desc 'Send backup to backupmyapp.com'
  
  task :start => :environment do
    @backuper = Backupmyapp.new
    @backuper.make_backup
  end
  
  desc "Send confirmation to backupmyapp.com"
  task :test => :environment do
    @backuper = Backupmyapp.new(false)
    @backuper.test
  end
end