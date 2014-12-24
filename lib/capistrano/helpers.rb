namespace :Capistrano do
  namespace :HelperMethods do
    
    def db_backup_path(prefix)
      "db_backups/#{prefix}_#{Time.now.to_i}.sql"
    end

  end
end
