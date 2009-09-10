class Backupmyapp
  class Error
    def self.no_key
      raise "No key found"
    end
    
    def self.backup_not_allowed
      raise "Backup not allowed now"
    end
  end
end