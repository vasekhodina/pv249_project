require 'gmail'
require './database_helper.rb'
Dotenv.load

##
# Class for creating reports from the database data with an example
# how to send them via gmail.
class Reporter
  GMAIL_USERNAME = ENV['GMAIL_USERNAME']
  GMAIL_PASSWORD = ENV['GMAIL_PASSWORD']

  def initialize()
    @db = DatabaseHelper.new
  end

  ## 
  # Generates a report in form of a file.
  # Stores it in a specified filepath.
  def generate_report(filepath)
    transactions = @db.get_unprocessed_trns
    file = File.open(filepath, 'w')
    file.puts 'Order_id    Date        Amount'
    for transaction in transactions do
      line = ''
      line += transaction[:order_id] + ' '
      line += transaction[:date].to_s + ' '
      line += transaction[:amount].to_s
      file.puts(line)
    end
    file.close
  end

  ##
  # Function that handles sending the file report from specified location
  # to the email address in first argument
  def send_gmail_report(receiver_email_address, report_filepath)
    gmail = Gmail.new(GMAIL_USERNAME, GMAIL_PASSWORD)
    gmail.deliver do
      to receiver_email_address
      subject "Vpsfree missing invoices alert"
      text_part do
        body "Hello, in the e-mail attachment, you will find the list of \
              transactions that are missing an invoice."
      end
      add_file report_filepath
    end
    gmail.logout
  end
end
