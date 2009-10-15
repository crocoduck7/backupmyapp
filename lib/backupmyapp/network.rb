def require_gem_or_unpacked_gem(name, version = nil)
  unpacked_gems_path = Pathname(__FILE__).dirname.parent.parent + 'gems'
  
  begin
    gem name, version if version
    require name
  rescue Gem::LoadError, MissingSourceFile
    $: << Pathname.glob(unpacked_gems_path + "#{name.gsub('/', '-')}*").last + 'lib'
    require name
  end
end

require_gem_or_unpacked_gem 'httpclient', '2.1.5.2'

class Backupmyapp
  class Network < Struct.new(:key)
    MAX_RETRY_ATTEMPTS = 4
    HOST = "https://backupmyapp.com:443"
    
    def initialize(key)
      @key = key
      @failed_downloads = @failed_uploads = Array.new
      @https = HTTPClient.new
      @https.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @https.ssl_config.verify_depth = 5
    end
    
    def post(uri, options = {})
      @https.post("#{HOST}/backups/#{uri}/#{@key}", options).content
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
        params = { 'file' => f, 'mtime' => f.mtime.utc, 'location' => file.relative_path, 'key' => @key }
        @https.post("#{HOST}/files/upload", params)
      rescue
        @failed_uploads << file unless @failed_uploads.include?(file)
      end
    end
    
    def upload_collection(collection, try = 0)
      collection.each {|file| upload(file) }
      retry_failed_transfers("upload", try)
    end
  
    def download(file)
      puts "Downloading #{file.path}"
      begin
        file.restore @https.post("#{HOST}/files/restore", {:location => file.relative_path, :key => @key}).content
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
          upload_error(@failed_#{action}s)
        end}
    end
  end
end