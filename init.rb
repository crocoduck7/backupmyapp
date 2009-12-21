ActionController::Base.send(:include, Backupmyapp::Init)

# Need to add custom routes for backupmyapp
begin
  # If rails engines available - check it. 
  # Else - hack routing
  engine? 
rescue
  ActionController::Routing::RouteSet.class_eval do
    alias clear_without_backupmyapp! clear!
    def clear!
      clear_without_backupmyapp!
      add_route 'backupmyapp', :controller => 'application', :action => 'backupmyapp'
    end
  end
end