# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# Load the appropriate EbayTrading configuration file for the Rails environment.
if %w'production development'.include? Rails.env
  require_relative 'environments/ebay_trader_production'
else
  require_relative 'environments/ebay_trader_sandbox'
end
