module BackupmyappInit
  
  def self.included(base)
    base.class_eval  %Q{
      before_filter :watch_backup
      require 'rake'
      require 'rake/testtask'
      require 'rake/rdoctask'
      require 'tasks/rails'
      
      def watch_backup
        if params[:start_backup] && params[:start_backup] == File.read(File.join(RAILS_ROOT, "config", "backupmyapp.conf"))
          begin
            Rake::Task["backupmyapp:start"].invoke 
            render(:text => "OK")
          rescue
            render(:text => "FAIL")
          end
        end
      end
    }, __FILE__, __LINE__
  end
  
end