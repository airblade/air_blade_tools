desc <<END
Start a MySQL shell using the credentials in database.yml.
Sake did this but one day Sake stopped working.  Strangely
Rails' databases.rake omits this task.

http://errtheblog.com/posts/60-sake-bomb
http://dev.rubyonrails.org/browser/trunk/railties/lib/tasks/databases.rake
END
namespace :db do
  task :shell => :environment do
    config = ActiveRecord::Base.configurations[(RAILS_ENV or "development")]
    command = ""
    case config["adapter"]
    when "mysql" then
      (command << "mysql ")
      (command << "--host=#{(config["host"] or "localhost")} ")
      (command << "--port=#{(config["port"] or 3306)} ")
      (command << "--user=#{(config["username"] or "root")} ")
      (command << "--password=#{(config["password"] or "")} ")
      (command << config["database"])
    when "postgresql" then
      puts("You should consider switching to MySQL or get off your butt and submit a patch")
    else
      (command << "echo Unsupported database adapter: #{config["adapter"]}")
    end
    system(command)
  end
end


desc %q@
Freezes Rails to edge, or a specific revision, with symlinks etc
as described by Mike Clark (see the Cadillac section):

* http://svn.techno-weenie.net/projects/mephisto/trunk/lib/tasks/common.rake
* http://www.clarkware.com/cgi/blosxom/2007/01/18#ManagingVersionsWithCap

Add this to your Capistrano script (config/deploy.rb):

  set :rails_version, XYZ unless variables[:rails_version]
  task :after_update_code, :roles => :app do
    run <<-CMD
      cd #{release_path} &&
      rake deploy_edge REVISION=#{rails_version} RAILS_PATH=/var/www/apps/rails
    CMD
  end
@
namespace 'deploy' do
  task :edge do
    ENV['SHARED_PATH']  = '../../shared' unless ENV['SHARED_PATH']
    ENV['RAILS_PATH'] ||= File.join(ENV['SHARED_PATH'], 'rails')
    ENV['REPO_BRANCH'] ||= 'trunk'
    
    checkout_path = File.join(ENV['RAILS_PATH'], 'trunk')
    export_path   = "#{ENV['RAILS_PATH']}/rev_#{ENV['REVISION']}"
    symlink_path  = 'vendor/rails'

    # do we need to checkout the file?
    unless File.exists?(checkout_path)
      puts 'setting up rails trunk'    
      get_framework_for checkout_path do |framework|
        system "svn co http://dev.rubyonrails.org/svn/rails/#{ENV['REPO_BRANCH']}/#{framework}/lib #{checkout_path}/#{framework}/lib --quiet"
      end
    end

    # do we need to export the revision?
    unless File.exists?(export_path)
      puts "setting up rails rev #{ENV['REVISION']}"
      get_framework_for export_path do |framework|
        system "svn up #{checkout_path}/#{framework}/lib -r #{ENV['REVISION']} --quiet"
        system "svn export #{checkout_path}/#{framework}/lib #{export_path}/#{framework}/lib"
      end
    end

    puts 'linking rails'
    rm_rf   symlink_path
    mkdir_p symlink_path

    get_framework_for symlink_path do |framework|
      ln_s File.expand_path("#{export_path}/#{framework}/lib"), "#{symlink_path}/#{framework}/lib"
    end
    
    touch "vendor/rails_#{ENV['REVISION']}"
  end

  def get_framework_for(*paths)
    %w( railties actionpack activerecord actionmailer activesupport activeresource actionwebservice ).each do |framework|
      paths.each { |path| mkdir_p "#{path}/#{framework}" }
      yield framework
    end
  end
end
