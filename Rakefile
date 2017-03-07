require 'rdoc/task'
require './database_helper'
Dotenv.load

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc', './*')
  rdoc.rdoc_dir = 'doc/'
end

task :send_report do
  require './reporter'
  reporter = Reporter.new
  reporter.generate_report('public/report.txt')
  reporter.send_gmail_report('vasek.hodina@gmail.com', 'public/report.txt')
end

task :get_data_and_send_report do
  require './database_helper'
  require './reporter'
  db = DatabaseHelper.new
  reporter = Reporter.new
  db.refresh(nil)
  reporter.generate_report('public/report.txt')
  reporter.send_gmail_report('vasek.hodina@gmail.com', 'public/report.txt')
end

task :create_sqlite_db do
  `sqlite3 invoice_reminder.db`
  `.quit`
end

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_t, args|
    require 'sequel'
    Sequel.extension :migration
    db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    if args[:version]
      puts 'Migrating to version #{args[:version]}'
      Sequel::Migrator.run(db, 'migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(db, 'migrations')
    end
  end
end

task :deploy_app do
  return unless check_env_file
  Rake::Task['db:migrate'].invoke
  db = DatabaseHelper.new
  puts 'Creating the first admin user.'
  db.create_user(ENV['ADMIN_USERNAME'], ENV['ADMIN_PASSWORD'], true)
  puts 'Done!'
  puts 'Downloading data from Fio'
  db.refresh(ENV['START_DATE'])
  puts 'Done!'
end

def check_env_file
  unless File.file?('./.env')
    puts 'Please configure .env file in root of this app to setup your application.'
    return false
  end
  true
end
