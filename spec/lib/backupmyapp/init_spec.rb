require File.dirname(__FILE__) + '/../../spec_helper'

Init = Backupmyapp::Init
describe Init do
  before(:each) do
    @controller = ActionController::Base
    @controller.send(:include, Init)
  end
  
  it "should set to application controller correct before_filter" do
    @controller.before_filters.should include(:watch_backup_actions)
  end

end