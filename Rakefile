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
