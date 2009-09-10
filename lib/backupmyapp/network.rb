class Backupmyapp
  class Network < Struct.new(:key)
    BMA_HOST = 'backupmyapp.com'

    def post(uri, options = {})
      http = Net::HTTP.new(BMA_HOST, 80)
      http.read_timeout = 3600
      params = CGI.escape options.collect {|k, v| "#{k}=#{v}"}.join("&")
      return http.post("/backups/#{uri}/#{key}", params).body
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
      post "error", {:body => "On #{action}: #{error}"}
    end
    
    def upload_error(files)
      error "Upload", files.map(&:path).join("\n")
    end
    
    def download_error(files)
      error "Download", files.map(&:path).join("\n")
    end
  end
end