require 'ebay_trading'

EbayTrading.configure do |config|

  # http://developer.ebay.com/DevZone/XML/docs/ReleaseNotes.html
  config.ebay_api_version = 931

  config.environment = :sandbox

  config.ebay_site_id = 3 # ebay.co.uk

  config.dev_id  = ENV['EBAY_API_DEV_ID']
  config.app_id  = ENV['EBAY_API_APP_ID']
  config.cert_id = ENV['EBAY_API_CERT_ID']

  config.price_type = :money

  config.store_auth_token(ENV['EBAY_API_USERNAME_T1'], ENV['EBAY_API_AUTH_TOKEN_T1'])
end
