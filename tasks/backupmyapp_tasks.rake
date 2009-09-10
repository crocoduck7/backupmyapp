namespace :backupmyapp do 
  
  desc 'Send backup to backupmyapp.com'
  
  task :backup => :environment do
    @backuper = Backupmyapp.new
    @backuper.backup
  end
  
  desc "Download data from backupmyapp.com"
  task :restore => :environment do
    @backuper = Backupmyapp.new
    @backuper.restore
  end
  
  desc "Send confirmation to backupmyapp.com"
  task :connect => :environment do
    @backuper = Backupmyapp.new(false)
    @backuper.test
  end
  
  desc "Restore database from dump"
  
  task :load_db => :environment do
    Backupmyapp::Database.load
    puts "Load success"
  end
end