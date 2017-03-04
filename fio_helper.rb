require 'typhoeus'
require 'json'
require 'dotenv'
Dotenv.load

TOKEN = ENV['TOKEN']
##
# Module for getting information from fio bank account
module FioHelper
  URL_GET_TRN='https://www.fio.cz/ib_api/rest/last/#token#/transactions.json'
  URL_SET_DAY='https://www.fio.cz/ib_api/rest/set-last-date/#token#/#rrrr-mm-dd#/'

  class << self
    ##
    # Downloads a list of transactions in form of a JSON file, parses it and returns a hash.
    # If since is not nil, sets the date from which the transactions should be downloaded.
    # If since arg. is nil, then downloads transactions since the last download
    def get_transactions(since)
      if since
        set_day(since)
      end
      response = Typhoeus::Request.new(URL_GET_TRN.sub!('#token#',TOKEN)).run.response_body
      JSON.parse(response)
    end

    ##
    # Sets a day from which the next update should be done.
    # This is a functionality provided by Fio API. More info at https://www.fio.cz/bank-services/internetbanking-api
    def set_day(from)
      URL_SET_DAY.sub!('#rrrr-mm-dd#', from)
      URL_SET_DAY.sub!('#token#',TOKEN)
      response = Typhoeus::Request.new(URL_SET_DAY).run.response_body
      return response
    end
  end
end
