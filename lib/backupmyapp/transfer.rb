class Backupmyapp
  class Transfer
    MAX_RETRY_ATTEMPTS = 4
    
    def initialize(config, server)
      @connection = Net::SCP.start(config[:domain], config[:user], :password => config[:password])
      @failed_downloads = @failed_uploads = Array.new
      @server = server
    end
  
    def upload(file)
      puts "Uploading #{file.path}"
      begin
        d = @connection.upload(file.path, file.remote_path, :preserve => true)
        d.wait
      rescue
        @failed_uploads << file unless @failed_uploads.include?(file)
      end
    end
  
    def download(file)
      puts "Downloading #{file.remote_path}"
      begin
        FileUtils.mkdir_p(file.local_folder)
        d = @connection.download(file.remote_path, file.path, :preserve => true)
        d.wait
      rescue
        @failed_downloads << file unless @failed_downloads.include?(file)
      end
    end
  
    def upload_collection(collection, try = 0)
      collection.each { |file| upload(file) }
      retry_failed_uploads("upload", try)
    end
  
    def download_collection(collection, try = 0)
      collection.each { |file| download(file) }
      retry_failed_uploads("download", try)
    end 
    
    def retry_failed_uploads(action, try)
      instance_eval %Q{
        try += 1
        if try < MAX_RETRY_ATTEMPTS
          #{action}_collection(@failed_#{action}s, try) && @failed_#{action}s.any?
        else
          @server.#{action}_error(@failed_#{action}s)
        end
      }
    end
  end
end