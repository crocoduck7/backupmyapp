class Backupmyapp
  module Downloader
    def self.download(file, request)
      FileUtils.mkdir_p(file.local_folder)
      File.open(path, 'w') {|f| f.write(content) }
    end
  end
end