namespace :backupmyapp do 
  
  desc 'Send backup to backupmyapp.com'
  
  task :start => :environment do
    @backuper = Backupmyapp.new
    @backuper.make_backup
  end
end