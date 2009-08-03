ActionController::Base.send(:include, BackupmyappInit)

ActionController::Routing::RouteSet.class_eval do
  def load_routes_with_named_routes!
    load_routes_without_named_routes!
    BackupmyappInit.add_routes 
  end
 
  alias_method_chain :load_routes!, :named_routes
end