require 'ebay_trading'
require 'ebay_trading/request'

class HomeController < ApplicationController
  def index
    @ebay_username = ENV['EBAY_API_USERNAME_TT']
    auth_token = EbayTrading.configuration.auth_token_for(@ebay_username)
    request = EbayTrading::Request.new('GeteBayOfficialTime', auth_token)
    @ebay_time = request.timestamp
  end
end
