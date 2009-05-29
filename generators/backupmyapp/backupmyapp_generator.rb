class BackupmyappGenerator < Rails::Generator::NamedBase
  
  def initialize(params, options)
    if params.any? && params[0] && params[0].downcase.match("key=[0-9a-zA-Z]+")
      @key = params[0].downcase.gsub("key=", '')
      super
    else
      raise "No key"
    end
  end
  
  def manifest
    record do |m|
      m.template 'backupmyapp.conf', 'config/backupmyapp.conf', :assigns => {:key => @key}
    end
    
  end
end
  