require 'sequel'
require 'pry'
require './fio_helper'
require 'digest'
require 'date'

class DatabaseHelper
  #@database = nil

  def initialize
    @database = Sequel.sqlite('./invoice_reminder.db')
  end

  # Positive transactions are those that either have an invoice attached
  #  or have a positive amount of money, ie. we don't need to attach
  #  include them in non-processed list
  def create_trn(transaction, positive)
    dataset = @database[:transactions]
    order_id = (transaction['column17'] ? transaction['column17']['value'] : nil)
    recv_account = (transaction['column2'] ? transaction['column2']['value'] : nil)
    recv_bank_num = (transaction['column3'] ? transaction['column3']['value'] : nil)
    c_symbol = (transaction['column4'] ? transaction['column4']['value'] : nil)
    v_symbol = (transaction['column5'] ? transaction['column5']['value'] : nil)
    s_symbol = (transaction['column6'] ? transaction['column6']['value'] : nil)
    dataset.insert(:id => transaction['column22']['value'],
                   :order_id => order_id,
                   :date => Date.parse(transaction['column0']['value']),
                   :amount => transaction['column1']['value'],
                   :recv_account => recv_account,
                   :recv_bank_num => recv_bank_num,
                   :c_symbol => c_symbol,
                   :v_symbol => v_symbol,
                   :s_symbol => s_symbol,
                   :invoice => nil,
                   :processed => positive)
  end

  def parse_account_info(account)
    # Count sum of positive and negative transactions
    sumPositive = @database[:transactions].where{ amount >= 0 }.sum(:amount)
    sumNegative = @database[:transactions].where{ amount < 0 }.sum(:amount)
    # Parse account infor
    dataset = @database[:account]
    dataset.insert(:id => account['accountId'],
                   :currency => account['currency'],
                   :update => Date.today,
                   :openingBalance => account['openingBalance'],
                   :closingBalance => account['closingBalance'],
                   :sumPositive => sumPositive,
                   :sumNegative => sumNegative)
  end

  def get_account_info
    @database[:account].all
  end

  def all_trns
    @database[:transactions].all
  end

  def positive_trns
    @database[:transactions].where{ amount >= 0 }.all
  end

  def negative_trns
    @database[:transactions].where{ amount < 0 }.all
  end

  def refresh(date)
    if date
      account_json = FioHelper.get_transactions(date)
    else
      account_json = FioHelper.get_transactions(nil)
    end
    # Parse individual transactions at the end of json
    for trn in account_json['accountStatement']['transactionList']['transaction'] do
      if (trn['column1']['value']).to_i < 0
        create_trn(trn, false)
      else
        create_trn(trn, true)
      end
    end
    if date
      parse_account_info(account_json['accountStatement']['info'])
    # else update only closing balance, date and sums in account
    end
  end

  def get_unprocessed_trns
    @database[:transactions].where(:processed => false).all
  end

  def upload_invoice(trn_id, file_path)
    @database[:transactions].where(:id => trn_id).update(:invoice => file_path)
    @database[:transactions].where(:id => trn_id).update(:processed => true)
  end

  def get_filepath(trn_id)
    row = @database[:transactions].where(:id => trn_id).all
    # Row is an array, so we need to take the first (and only member)
    # and then take invoice path from there
    row[0][:invoice]
  end

  def delete_invoice(trn_id)
    @database[:transactions].where(:id => trn_id).update(:invoice => nil)
    @database[:transactions].where(:id => trn_id).update(:processed => false)
  end

  def check_user(username, password)
    row = @database[:users].where(:name => username).all
    if row[0][:password] == password
      return true
    else
      return false
    end
  end

  def get_user(username)
    row = @database[:users].where(:name => username).all
    return row[0]
  end

  def create_user(username, password, admin)
    @database[:users].insert(:name => username, :password => password, :admin => admin)
  end

  def delete_user(username)
    @database[:users].where(:name => username).delete
  end

  def get_users
    @database[:users].all
  end
end
