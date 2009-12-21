class Backupmyapp
  module Init
    def self.included(base)
      base.class_eval do
        before_filter :watch_backup_actions
    
        def watch_backup_actions
          if params[:start_backup]
            @backuper = Backupmyapp.new
            @backuper.backup
          elsif params[:start_restore]
            @backuper = Backupmyapp.new
            @backuper.restore
          elsif params[:check_installed]
            render :text => "installed"
          end
        end
      end
    end
  end
end