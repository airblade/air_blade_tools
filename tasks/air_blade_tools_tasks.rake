namespace :rails do
  namespace :upgrade do

    desc 'Renames deprecated view extensions, e.g. foo.rhtml => foo.html.erb'
    task :views do
      Dir.glob('app/views/**/[^_]*.rhtml').each do |file|
        puts `svn mv #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
      end

      Dir.glob('app/views/**/[^_]*.rjs').each do |file|
        puts `svn mv #{file} #{file.gsub(/\.rjs$/, '.js.rjs')}`
      end

      Dir.glob('app/views/**/[^_]*.rxml').each do |file|
        puts `svn mv #{file} #{file.gsub(/\.rxml$/, '.xml.builder')}`
      end

      Dir.glob('app/views/**/[^_]*.haml').each do |file|
        puts `svn mv #{file} #{file.gsub(/\.haml$/, '.html.haml')}`
      end
    end

  end
end

namespace :db do

  desc <<-END
  Start a MySQL shell using the credentials in database.yml.
  Sake did this but one day Sake stopped working.  Strangely
  Rails' databases.rake omits this task.

  http://errtheblog.com/posts/60-sake-bomb
  http://dev.rubyonrails.org/browser/trunk/railties/lib/tasks/databases.rake
  END
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

  namespace :fixtures do
    desc <<-END
    Loads basic data into the current environment's database.  Load specific fixtures using FIXTURES=x,y.

    This differs from db:fixtures:load by loading fixtures in the db/basic_data directory rather than text/fixtures.  Basic data, a.k.a. reference data, and test data serve different purposes and should not be conflated.

    This is a better way to load basic data than within migrations because migrations are not guaranteed to run through from start to finish.  The recommended way to create a new database with the current structure is via db/schema.rb.  So if we cannot rely on the migrations, we should not use them to load basic data.
    END
    task :basic_data => :environment do
      require 'active_record/fixtures'
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
      (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'db', 'basic_data', '*.{yml,csv}'))).each do |fixture_file|
        Fixtures.create_fixtures('db/basic_data', File.basename(fixture_file, '.*'))
      end
    end
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
