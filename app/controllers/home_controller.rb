require 'ebay_trader'
require 'ebay_trader/request'

class HomeController < ApplicationController
  def index
    @ebay_username = ENV['EBAY_API_USERNAME_TT']
    auth_token = EbayTrader.configuration.auth_token_for(@ebay_username)
    request = EbayTrader::Request.new('GeteBayOfficialTime', auth_token: auth_token)
    @ebay_time = request.timestamp
  end
end
