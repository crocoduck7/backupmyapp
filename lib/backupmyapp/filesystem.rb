class Backupmyapp
  module Filesystem
    def app_file_structure(root = RAILS_ROOT)
      list_dir(RAILS_ROOT)
    end

    def root_directories
      Dir.glob("#{RAILS_ROOT}/*/").join(" ").gsub(RAILS_ROOT, '')
    end

    def list_dir(dir, snapshot = "")
      related_dir_path = dir.gsub(RAILS_ROOT, '')
      Dir.new("#{dir}").each do |file|
        next if file.match(/^\.+/)

        path = "#{dir}/#{file}"
        if FileTest.directory?(path)
          list_dir(path, snapshot)
        elsif allowed?(path) && File.exists?(path)
          base_path =  "#{related_dir_path}/#{file}"
          stat = File::Stat.new(path)
          snapshot << "#{short_time(stat.mtime.utc)} #{stat.size} #{base_path}\n"
        end
      end

      return snapshot
    end
  end
end