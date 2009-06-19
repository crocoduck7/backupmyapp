module BackupmyappInit
  
  def self.included(base)
    base.class_eval  %Q{
      before_filter :watch_backup
      before_filter :watch_restore
      
      require 'rake'
      require 'rake/testtask'
      require 'rake/rdoctask'
      require 'tasks/rails'
      
      def watch_backup
        if params[:start_backup] && params[:start_backup] == File.read(File.join(RAILS_ROOT, "config", "backupmyapp.conf"))
          begin
            Rake::Task["backupmyapp:backup"].invoke 
            render(:text => "OK")
          rescue
            render(:text => "FAIL")
          end
        end
      end
      
      def watch_restore
        if params[:start_restore] && params[:start_restore] == File.read(File.join(RAILS_ROOT, "config", "backupmyapp.conf"))
          begin
            Rake::Task["backupmyapp:restore"].invoke 
            render(:text => "OK")
          rescue
            render(:text => "FAIL")
          end
        end
      end
    }, __FILE__, __LINE__
  end
  
end