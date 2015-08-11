require "#{Rails.root}/app/workers/get_item_worker"
require "#{Rails.root}/app/workers/get_user_worker"

namespace :request do

  # $ ./bin/rake request:get_item[ebay-username,123456789] RAILS_ENV=production
  desc 'Request the details for a single eBay item ebay_listing'
  task :get_item, [:ebay_username, :item_id] do |t, args|
    begin
      username = args[:ebay_username]
      auth_token = EbayTrading.configuration.auth_token_for(username)
      raise "Could not find auth token for eBay username '#{username}'" if auth_token.nil?

      item_id = (args[:item_id] || 0).to_i
      raise 'Please provide eBay item ID' unless item_id > 0

      puts "Requesting eBay item '#{item_id}' data on behalf of '#{username}'"
      GetItemWorker.perform_async(auth_token, item_id)
    rescue Exception => e
      puts e.message
    end
  end


  # $ ./bin/rake request:get_user[ebay-username]
  desc 'Request the details for an eBay user'
  task :get_user, [:ebay_username] do |t, args|
    begin
      user_id = args[:ebay_username]
      puts "Requesting eBay user details for '#{user_id}'"
      auth_token = EbayTrading.configuration.auth_token_for(user_id)
      if auth_token.nil?
        # If auth_token is nil it means the user whose details are requested
        # is not one of my accounts. In this case just use any one of my
        # production auth_tokens.
        my_user_id = ENV['EBAY_API_USERNAME_TT']
        auth_token = EbayTrading.configuration.auth_token_for(my_user_id)
        puts "  using auth token from #{my_user_id}"
      end

      GetUserWorker.perform_async(auth_token, user_id)
    rescue Exception => e
      puts e.message
    end
  end
end
