class Backupmyapp
  module Filesystem
    
    def app_file_structure(root = RAILS_ROOT, arr = [])
      list_dir(RAILS_ROOT).join("\n")
    end

    def root_directories
      Dir.glob("#{RAILS_ROOT}/*/").join(" ").gsub(RAILS_ROOT, '')
    end

    def list_dir(dir, arr=[])
      Dir.new("#{dir}").each do |file|
        next if file.match(/^\.+/)

        path = "#{dir}/#{file}"
        if FileTest.directory?(path)
          list_dir(path, arr)
        elsif allowed?(path) && File.exists?(path)
          arr << "#{short_time(File.mtime(path).utc)} #{File.size(path)} #{path.gsub(RAILS_ROOT, '')}"
        end
      end

      return arr
    end
    
  end
end