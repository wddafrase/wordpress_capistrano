namespace :wp do
  namespace :setup do

    desc "Set permissions on files"
    task :set_permissions do
      on roles :web do
        execute :chmod, "-R 777 #{shared_path}/content/uploads"
      end
    end

    desc "Create files for linking"
    task :create_wp_link_files do
      on roles :app do
        execute :touch, "#{shared_path}/production-config.php"
      end
    end

    desc "Download the wordpress core files"
    task :core do
      on roles :app do
        within release_path do
          execute :curl, "#{fetch(:wp_core)} | tar xz -C wp --strip-components 1"
          execute :rm, "-rf wp/wp-content"

          db = fetch :database
          db_config = ERB.new(File.read('lib/capistrano/templates/db-config.php.erb')).result(binding)
          upload! StringIO.new(db_config), "#{shared_path}/production-config.php"

          execute :chmod, "+r #{shared_path}/production-config.php"
        end
      end
    end

  end
end
