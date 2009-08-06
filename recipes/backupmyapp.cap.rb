namespace :backupmyapp do
  desc "Test connection to backupmyapp.com"
  task :connect, :only => { :primary => true } do
    rails_env = fetch(:rails_env, "production")
    run "cd #{current_path}; rake backupmyapp:connect RAILS_ENV=#{rails_env}"
  end

  desc "Send backup to backupmyapp.com"
  task :backup, :only => {:primary => true } do
    rails_env = fetch(:rails_env, "production")
    run "cd #{current_path}; rake backupmyapp:backup RAILS_ENV=#{rails_env}"
  end

  desc "Restore backup from backupmyapp.com"  
  task :restore, :only => {:primary => true } do
    rails_env = fetch(:rails_env, "production")
    run "cd #{current_path}; rake backupmyapp:restore RAILS_ENV=#{rails_env}"
  end
end