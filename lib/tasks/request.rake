require "#{Rails.root}/app/workers/get_item_worker"

# Example GetItem rake task call...
#
# $ ./bin/rake request:get_item[tantric-tokyo,123456789] RAILS_ENV=production

namespace :request do

  desc 'Request the details for a single eBay item listing'
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
end
