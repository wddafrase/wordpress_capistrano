# TODO: Remove code duplication
namespace :uploads do
  
  desc "Push uploads to remote server"
  task :push do
    run_locally do
      roles(:web).each do |role|
        execute :rsync, "-azO -e \"ssh -i #{fetch(:ssh_options)[:keys][0]}\" content/uploads/ #{role.user}@#{role.hostname}:#{shared_path}/content/uploads"
      end
    end
  end

  desc "Push uploads to remote server and delete files that don't exist locally"
  task :push! do
    run_locally do
      roles(:web).each do |role|
        execute :rsync, "-azO --delete-after -e \"ssh -i #{fetch(:ssh_options)[:keys][0]}\" content/uploads/ #{role.user}@#{role.hostname}:#{shared_path}/content/uploads"
      end
    end
  end

  desc "Pull uploads from a remote server"
  task :pull do
    run_locally do
      roles(:web).each do |role|
        execute :rsync, "-azO -e \"ssh -i #{fetch(:ssh_options)[:keys][0]}\" #{role.user}@#{role.hostname}:#{shared_path}/content/uploads/ content/uploads"
      end
    end
  end

  desc "Pull uploads from a remote server and deletes files that don't exist remotely"
  task :pull! do
    run_locally do
      roles(:web).each do |role|
        execute :rsync, "-azO --delete-after -e \"ssh -i #{fetch(:ssh_options)[:keys][0]}\" #{role.user}@#{role.hostname}:#{shared_path}/content/uploads/ content/uploads"
      end
    end
  end

end
