require 'sequel'
require './fio_helper'
require 'digest'
require 'date'

##
# Class for hadnling all the database interactions. The very core
# of this application.
class DatabaseHelper
  ##
  # Constructor for this class. Connects to the database.
  def initialize
    @database = Sequel.sqlite('./invoice_reminder.db')
  end

  ##
  # This function goes through the list of transactions and stores
  # each one in the database.
  # Positive transactions are those that either have an invoice attached
  # or have a positive amount of money, ie. we don't need to attach
  # include them in non-processed list
  def create_trn(transaction, positive)
    dataset = @database[:transactions]
    dataset.insert(id: transaction['column22']['value'],
                   order_id: assign_safely(transaction, 'column17'),
                   date: Date.parse(transaction['column0']['value']),
                   amount: transaction['column1']['value'],
                   recv_account: assign_safely(transaction, 'column2'),
                   recv_bank_num: assign_safely(transaction, 'column3'),
                   c_symbol: assign_safely(transaction, 'column4'),
                   v_symbol: assign_safely(transaction, 'column5'),
                   s_symbol: assign_safely(transaction, 'column6'),
                   invoice: nil,
                   processed: positive)
  end

  ##
  # Helper function for handling weird format of Fio Bank JSON.
  # If some value is missing, then the whole colums is missing,
  # but when the column is there the data we need is in ['value']
  # subelement.
  # This function handles 'no method [] for nil Class' errors.
  def assign_safely(transaction, column_id)
    transaction[column_id] ? transaction[column_id]['value'] : nil
  end

  ##
  # Function that extracts data for Dashboard from Fio JSON
  def parse_account_info(account)
    dataset = @database[:account]
    dataset.insert(id: account['accountId'],
                   currency: account['currency'],
                   update: Date.today,
                   openingBalance: account['openingBalance'],
                   closingBalance: account['closingBalance'],
                   sumPositive: sum_positive_transactions,
                   sumNegative: sum_negative_transactions)
  end

  def update_account_info(account)
    @database[:account].where(accountId: account['accountId'])
                       .update(update: Date.today,
                               closingBalance: account['closingBalance'],
                               sumPositive: sum_positive_transactions,
                               sumNegative: sum_negative_transactions)
  end

  ##
  # Summing all transactions from the database that have
  # amount of 0 or more
  def sum_positive_transactions
    @database[:transactions].where { amount >= 0 }.sum(:amount)
  end

  ##
  # Summing all transactions from the database that have
  # amount less than 0
  def sum_negative_transactions
    @database[:transactions].where { amount < 0 }.sum(:amount)
  end

  ##
  # Function that provides data about account from DB
  def account_info
    @database[:account].all
  end

  ##
  # Returning all transactions from database
  def all_trns
    @database[:transactions].all
  end

  ##
  # Returning all positive transactions from database
  def positive_trns
    @database[:transactions].where { amount >= 0 }.all
  end

  ##
  # Returning all negative transactions from database
  def negative_trns
    @database[:transactions].where { amount < 0 }.all
  end

  ##
  # Downloads new current JSON from Fio and updates the database.
  # Creating all the transactions and updating account data.
  def refresh(date)
    account_statement = FioHelper.get_account_statement(date)
    account_statement['transactionList']['transaction'].each do |trn|
      if (trn['column1']['value']).to_i < 0
        create_trn(trn, false)
      else
        create_trn(trn, true)
      end
    end
    if date 
      parse_account_info(account_statement['info'])
    else 
      update_account_info(account_statement['info'])
    end
  end

  ##
  # Returns all the transactions that have a processed attribute set to false
  def unprocessed_trns
    @database[:transactions].where(processed: false).all
  end

  ##
  # Function that handles the file uploading process in the DB.
  def upload_invoice(trn_id, file_path)
    @database[:transactions].where(id: trn_id).update(invoice: file_path)
    @database[:transactions].where(id: trn_id).update(processed: true)
  end

  ##
  # Return the filepath of uploaded file from DB for the specified transaction.
  def get_filepath(trn_id)
    @database[:transactions].where(id: trn_id).all[0][:invoice]
    # Row is an array, so we need to take the first (and only member)
    # and then take invoice path from there
    # row[0][:invoice]
  end

  ##
  # Handles deleting of filepath in database. Also sets the processed
  # attribute to false.
  def delete_invoice(trn_id)
    @database[:transactions].where(id: trn_id).update(invoice: nil)
    @database[:transactions].where(id: trn_id).update(processed: false)
  end

  ##
  # Checks if the user exists and if the password is correct
  def check_user(username, password)
    row = @database[:users].where(name: username).all
    row[0][:password] == password
  end

  ##
  # Return the information about the user.
  def get_user(username)
    @database[:users].where(name: username).all
  end

  ##
  # Creates a new user DB entry.
  def create_user(username, password, admin)
    @database[:users].insert(name: username, password: password, admin: admin)
  end

  def update_user(username, admin)
    @database[:users].where(name: username).update(admin: admin)
  end

  ##
  # Deletes the user entry from database.
  def delete_user(username)
    @database[:users].where(name: username).delete
  end

  ##
  # Return all lines in users table.
  def users
    @database[:users].all
  end
end
