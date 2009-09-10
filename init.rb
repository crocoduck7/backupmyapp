ActionController::Base.send(:include, Backupmyapp::Init)

ActionController::Routing::RouteSet.class_eval do
  def clear_with_clear_backupmyapp!
    clear_without_clear_backupmyapp!
    add_route 'backupmyapp', :controller => 'application', :action => 'backupmyapp'
  end
  
  alias_method_chain :clear!, :clear_backupmyapp
end