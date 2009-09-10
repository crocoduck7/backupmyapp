class Backupmyapp
  module Timestamps
    def trim_timestamps(text)
      text.gsub(/\d{14} \d+ /, '')
    end

    def short_time(date)
      date.utc.strftime("%Y%m%d%H%M%S")
    end
    
    def short_mtime(path)
      short_time(File.mtime(path).utc)
    end
  end
end