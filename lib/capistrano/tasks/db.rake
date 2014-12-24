namespace :db do
  
  desc "Backup remote database and download to local"
  task :backup_remote do
    set :remote_backup_file, db_backup_path('remote') unless fetch(:remote_backup_file)
    
    run_locally do
      execute :mkdir, "-p #{File.dirname fetch(:remote_backup_file)}"
    end

    on roles :db do
      within release_path do
        execute :mkdir, "-p #{shared_path}/#{File.dirname fetch(:remote_backup_file)}"
        execute :wp, :db, :export, "#{shared_path}/#{fetch(:remote_backup_file)} --add-drop-table"
      end

      download! "#{shared_path}/#{fetch(:remote_backup_file)}", fetch(:remote_backup_file)

      execute :rm, "#{shared_path}/#{fetch(:remote_backup_file)}"
    end
  end

  desc "Backup local database"
  task :backup_local do
    set :local_backup_file, db_backup_path('local') unless fetch(:local_backup_file)

    run_locally do
      execute :mkdir, "-p #{File.dirname fetch(:local_backup_file)}"
      execute :wp, :db, :export, "#{fetch(:local_backup_file)} --add-drop-table"
    end
  end

  desc "Import the remote database into local enironment"
  task :pull => [:backup_local, :backup_remote] do
    run_locally do
      execute :wp, :db, :import, fetch(:remote_backup_file)
      execute :wp, "search-replace #{fetch(:wp_url)} #{fetch(:wp_dev_url)}"
      execute :rm, fetch(:remote_backup_file)
    end
  end

  desc "Import the local database into remote enironment"
  task :push => [:backup_remote, :backup_local] do
    on roles :db do
      # upload local db backup to remote
      upload! fetch(:local_backup_file), "#{shared_path}/#{fetch(:local_backup_file)}"

      # import the database then replace local urls and delete the db file on remote machine
      within release_path do
        execute :wp, :db, :import, "#{shared_path}/#{fetch(:local_backup_file)}"
        execute :wp, "search-replace #{fetch(:wp_dev_url)} #{fetch(:wp_url)}"
        execute :rm, "#{shared_path}/#{fetch(:local_backup_file)}"
      end
    end

    run_locally do
      execute :rm, fetch(:local_backup_file)
    end
  end

  desc "Change the local db config to use remote mysql"
  task :use_remote do
    run_locally do
      db = fetch(:database)
      
      if db[:host].eql?('localhost') || db[:host].eql?('127.0.0.1')
        db[:host] = roles(:db)[0].hostname
      end
      
      db_config = ERB.new(File.read('lib/capistrano/templates/db-config.php.erb')).result(binding)
      File.open('local-config.php', 'w') { |f| f.write(db_config) }

      execute :chmod, '+r local-config.php'
    end
  end

  desc "Change local db config to use local mysql"
  task :use_local do
    run_locally do
      db = fetch(:database)
      db[:host] = 'localhost'
      db[:user] = 'wp'
      db[:pass] = 'wp'

      db_config = ERB.new(File.read('lib/capistrano/templates/db-config.php.erb')).result(binding)
      File.open('local-config.php', 'w') { |f| f.write(db_config) }

      execute :chmod, '+r local-config.php'
    end
  end

  desc "Rollback local database to most recent backup"
  task :rollback_local do
    set :local_backup_file, db_backup_path('before_local_rollback')
    invoke 'db:backup_local'

    run_locally do
      db_files = Dir[File.join('db_backups', '*')].select { |e| File.basename(e).start_with?('local') }
      db_files.sort_by! { |a| a.downcase }
      execute :wp, :db, :import, db_files.last
    end
  end

  desc "Rollback remote database to most reset backup"
  task :rollback_remote do
    set :remote_backup_file, db_backup_path('before_remote_rollback')
    invoke 'db:backup_remote'
    
    backup_file = nil
    run_locally do
      db_files = Dir[File.join('db_backups', '*')].select { |e| File.basename(e).start_with?('remote') }
      db_files.sort_by! { |a| a.downcase }
      backup_file = db_files.last
    end

    on roles :db do
      upload! backup_file, "#{shared_path}/#{backup_file}"

      within release_path do
        execute :wp, :db, :import, "#{shared_path}/#{backup_file}"
        execute :rm, "#{shared_path}/#{backup_file}"
      end
    end
  end

end
