# https://www.fio.cz/ib_api/rest/periods/{token}/{datum od}/{datum do}/transactions.{format}
#  TOKEN='HwvbHP1aJSBQKSYQ6WWFP0Ri25BchvXx1gLyCMZgk97lJZpeb6mirQOpg1VK7ZWW'
# acc: 2200041594
# example: https://www.fio.cz/ib_api/rest/periods/HwvbHP1aJSBQKSYQ6WWFP0Ri25BchvXx1gLyCMZgk97lJZpeb6mirQOpg1VK7ZWW/2017-01-01/2017-01-31/transactions.json
require 'typhoeus'
require 'json'
require 'dotenv'
Dotenv.load

TOKEN = ENV['TOKEN']

module FioHelper
  URL_GET_TRN='https://www.fio.cz/ib_api/rest/last/#token#/transactions.json'
  URL_SET_DAY='https://www.fio.cz/ib_api/rest/set-last-date/#token#/#rrrr-mm-dd#/'

  class << self
    def get_transactions(since)
      if since
        set_day(since)
      end
      response = Typhoeus::Request.new(URL_GET_TRN.sub!('#token#',TOKEN)).run.response_body
      JSON.parse(response)
    end

    def set_day(from)
      URL_SET_DAY.sub!('#rrrr-mm-dd#', from)
      URL_SET_DAY.sub!('#token#',TOKEN)
      response = Typhoeus::Request.new(URL_SET_DAY).run.response_body
      return response
    end
  end
end
