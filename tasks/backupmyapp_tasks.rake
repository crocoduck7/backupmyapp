namespace :backupmyapp do 
  
  desc 'Send backup to backupmyapp.com'
  
  task :backup => :environment do
    @backuper = Backupmyapp.new
    @backuper.backup
  end
  
  task :restore => :environment do
    @backuper = Backupmyapp.new
    @backuper.restore
  end
  
  desc "Send confirmation to backupmyapp.com"
  task :test => :environment do
    @backuper = Backupmyapp.new(false)
    @backuper.test
  end
end