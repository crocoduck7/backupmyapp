class BackupFile
  def initialize(path, remote)
    @path = path
    @remote_path = remote
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
end