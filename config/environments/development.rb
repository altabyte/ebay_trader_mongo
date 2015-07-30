require 'ebay_trading'

EbayTrading.configure do |config|
  config.environment = :production
  config.ebay_site_id = 3 # ebay.co.uk
  config.dev_id  = ENV['EBAY_API_DEV_ID']
  config.app_id  = ENV['EBAY_API_APP_ID']
  config.cert_id = ENV['EBAY_API_CERT_ID']

  config.store_auth_token(ENV['EBAY_API_USERNAME_AR'], ENV['EBAY_API_AUTH_TOKEN_AR'])
  config.store_auth_token(ENV['EBAY_API_USERNAME_TT'], ENV['EBAY_API_AUTH_TOKEN_TT'])
end

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end
