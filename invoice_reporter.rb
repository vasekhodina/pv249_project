require 'gmail'
require './database_helper'

class InvoiceReporter
  def send_gmail_report
    #gmail = Gmail.new(USERNAME, PASSWORD)
    gmail.deliver do
      to "wasseker@gmail.com"
      subject "Missing invoices for outgoing transactions!"
      text_part do
        body "Here is the list of transactions missing an invoice.\n"
      end
    end
    gmail.logout
  end

  def generate_trns()
    db = DatabaseHelper.connect_to_db
    trns = DatabaseHelper.get_unprocessed_trns(db)
    trns_string = ""
    trns.each do |trn|
      trns_string = trns_string + trn[:id].to_s + " " + trn[:date].to_s + " " + trn[:amount].to_s + "\n"
    end
    return trns_string
  end

  def generate_file()
    File.open('./public/report.txt', 'w') { |file| file.write(self.generate_trns) }
  end
end
