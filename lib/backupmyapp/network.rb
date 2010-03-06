require 'rest_client/rest_client'

class Backupmyapp
  class Network
    MAX_RETRY_ATTEMPTS = 4
    HOST = "https://backupmyapp.com"
    PLUGIN_VERSION = '1.0.6'
    
    def initialize(key)
      @key = key
      @failed_downloads = @failed_uploads = Array.new
      @https = RestClient
    end
    
    def post(uri, options = {})
      options.merge!({'plugin_version' => PLUGIN_VERSION })
      @https.post("#{HOST}/backups/#{uri}/#{@key}", options)
    end
    
    def init(action, directories)
      post "init/#{action}", {'directories' => directories}
    end
    
    def diff(files)
      post "diff", {'files' => files }
    end
    
    def restore
      post "restore"
    end
    
    def test
      post "test"
    end
    
    def finish(action)
      post "finish/#{action}"
    end
    
    def error(action, error)
      post "error", {:body => "On #{action}: #{error}", :hash => @key}
    end
    
    def upload_error(files)
      error "Upload", files.map(&:path).join("\n")
    end
    
    def download_error(files)
      error "Download", files.map(&:path).join("\n")
    end
    
    def upload(file)
      puts "Uploading #{file.path}"      
      begin
        f = File.new(file.path)
        params = {
          'file' => f,
          'mtime' => f.mtime.utc.strftime("%m/%d/%Y %H:%M:%S %Z"),
          'location' => file.relative_path,
          'key' => @key
        }
        
        @https.post("#{HOST}/files/upload", params)
      rescue
        @failed_uploads << file unless @failed_uploads.include?(file)
      end
    end
    
    def upload_collection(collection, try = 0)
      collection.each_slice(12) do |slice|
        threads = []
        slice.each do |file| 
          threads << Thread.new do
            upload(file)
          end
        end
        
        threads.each {|t| t.join }
      end
      retry_failed_transfers("upload", try)
    end
  
    def download(file)
      puts "Downloading #{file.path}"
      begin
        file.restore @https.post("#{HOST}/files/restore", {:location => file.relative_path, :key => @key})
      rescue
        @failed_downloads << file unless @failed_downloads.include?(file)
      end
    end
  
    def download_collection(collection, try = 0)
      collection.each {|file| download(file) }
      retry_failed_transfers("download", try)
    end
    
    def retry_failed_transfers(action, try)
      instance_eval %Q{
        try += 1
        if try < MAX_RETRY_ATTEMPTS
          #{action}_collection(@failed_#{action}s, try) && @failed_#{action}s.any?
        else
          upload_error(@failed_#{action}s) if @failed_#{action}s.any?
        end}
    end
  end
end