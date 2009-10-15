class Backupmyapp
  class BackupFile
    def initialize(path, remote)
      @path = path
      @remote_path = remote
    end
    
    def relative_path
      @path
    end
  
    def path
      File.join(RAILS_ROOT, @path)
    end
  
    def remote_path
      File.join(@remote_path, @path)
    end
  
    def remote_folder
      remote_path.gsub(File.basename(@path), '')
    end
  
    def local_folder
      path.gsub(File.basename(@path), '')
    end
    
    def restore(content)
      FileUtils.mkdir_p(local_folder)
      File.open(path, 'w') {|f| f.write(content) }
      content = ""
    end
  end
end