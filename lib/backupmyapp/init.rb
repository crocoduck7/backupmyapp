class Backupmyapp
  module Init
    def self.included(base)
      base.class_eval do
        skip_before_filter filter_chain, :only => [:backupmyapp]
        before_filter :watch_backup_actions
        
        def watch_backup_actions
          begin
            process_backups_if_required
          rescue
            render :text => "Error occured: $!"
          end
        end
        
        def process_backups_if_required
          if params[:start_backup]
            process_backup_in_fork
          elsif params[:start_restore]
            process_restore_in_fork
          elsif params[:check_installed]
            render :text => "installed"
          end
        end
        
        def process_backup_in_fork
          f = Process.fork do
            @backuper = Backupmyapp.new
            @backuper.backup
            exit!(0)
          end
          
          Process.detach(f)
        end
        
        def process_restore_in_fork
          f = Process.fork do
            @backuper = Backupmyapp.new
            @backuper.restore
            exit!(0)
          end
          
          Process.detach(f)
        end
        
      end
    end
  end
end