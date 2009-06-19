require File.dirname(__FILE__) + '/../spec_helper'

describe BackupmyappInit do
  before(:each) do
    @controller = ActionController::Base
    @controller.send(:include, BackupmyappInit)
  end
  
  it "should set to application controller correct before_filter" do
    @controller.before_filters.should include(:watch_backup)
    @controller.before_filters.should include(:watch_restore)
  end
  
  describe "watch_backup method" do
    
  end
end