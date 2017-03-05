require 'typhoeus'
require 'json'
require 'dotenv'
Dotenv.load

TOKEN = ENV['TOKEN']
##
# Module for getting information from fio bank account
module FioHelper
  class << self
    ##
    # Downloads a list of transactions in form of a JSON file, parses it and
    # returns a hash.
    # If since is not nil, sets the date from which the transactions should be
    # downloaded.
    # If since arg. is nil, then downloads transactions since the last download
    def get_transactions(since)
      get_trn_url = 'https://www.fio.cz/ib_api/rest/last/#token#/transactions.json'
      fio_set_day(since) if since
      response = Typhoeus::Request.new(get_trn_url.sub!('#token#', TOKEN)).run.response_body
      JSON.parse(response)
    end

    ##
    # Sets a day from which the next update should be done.
    # This is a functionality provided by Fio API.
    # More info at https://www.fio.cz/bank-services/internetbanking-api
    def fio_set_day(from)
      set_day_url = 'https://www.fio.cz/ib_api/rest/set-last-date/#token#/#rrrr-mm-dd#/'
      set_day_url.sub!('#rrrr-mm-dd#', from)
      set_day_url.sub!('#token#', TOKEN)
      Typhoeus::Request.new(set_day_url).run.response_body
    end
  end
end
