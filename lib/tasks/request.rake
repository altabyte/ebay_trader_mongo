require "#{Rails.root}/app/workers/get_item_worker"
require "#{Rails.root}/app/workers/get_user_worker"

namespace :request do

  # Get the default eBay user ID to use in cases where no user ID is provided.
  def default_ebay_user_id
    ENV['EBAY_API_USERNAME_TT']
  end

  def default_auth_token
    EbayTrading.configuration.auth_token_for(default_ebay_user_id)
  end


  # $ ./bin/rake request:get_user[ebay-username]
  desc 'Request the details for an eBay user'
  task :get_user, [:ebay_username] do |_, args|
    begin
      ebay_user_id = args[:ebay_username]
      puts "Requesting details for eBay user '#{ebay_user_id}'"

      ebay_user = EbayUser.where(user_id: ebay_user_id).first
      if ebay_user && ebay_user.ebay_account
        auth_token = ebay_user.ebay_account.auth_token
      else
        auth_token = default_auth_token
      end

      GetUserWorker.perform_async(auth_token, ebay_user_id)
    rescue Exception => e
      puts e.message
    end
  end


  # $ ./bin/rake request:get_item[ebay-username,123456789] RAILS_ENV=production
  desc 'Request the details for a single eBay item ebay_listing'
  task :get_item, [:ebay_username, :item_id] do |_, args|
    begin
      ebay_user_id = args[:ebay_username]
      ebay_user = EbayUser.where(user_id: ebay_user_id).first
      if ebay_user && ebay_user.ebay_account
        auth_token = ebay_user.ebay_account.auth_token
      else
        raise "Could not find auth token for eBay username '#{ebay_user_id}'"
      end

      item_id = (args[:item_id] || 0).to_i
      raise 'Please provide eBay item ID' unless item_id > 0

      puts "Requesting eBay item '#{item_id}' data on behalf of '#{ebay_user_id}'"
      GetItemWorker.perform_async(auth_token, item_id)
    rescue Exception => e
      puts e.message
    end
  end


  # $ ./bin/rake request:get_seller_list[ebay-username] RAILS_ENV=production
  desc 'Request an eBay sellers complete list of items'
  task :get_seller_list, [:ebay_username] do |_, args|
    begin
      ebay_user_id = args[:ebay_username]
      puts "Requesting seller list for eBay user '#{ebay_user_id}'"

      ebay_user = EbayUser.where(user_id: ebay_user_id).first
      if ebay_user && ebay_user.ebay_account
        auth_token = ebay_user.ebay_account.auth_token
      else
        auth_token = default_auth_token
      end

      GetSellerListWorker.perform_async(auth_token, ebay_user_id)
    rescue Exception => e
      puts e.message
    end
  end


  # $ ./bin/rake request:sync_ebay_listings RAILS_ENV=production
  desc 'Updated details of all eBay listings in MongoDB'
  task :sync_ebay_listings do |_, _|
    begin
      EbayAccount.each do |account|
        auth_token = account.auth_token
        ebay_user_id = account.ebay_user.user_id if account.ebay_user && account.ebay_user.user_id

        GetSellerListWorker.perform_async(auth_token, ebay_user_id) unless ebay_user_id.nil?

        # @ToDo
        #
        # Also synchronize seller events to update status of sold out items
        # as these will be absent from GetSellerList calls!
        #
        event_type = 'Ended'
        time_from = (Time.now.utc - 3.days).to_s
        time_to = nil

        GetSellerEventsWorker.perform_async(auth_token, event_type, time_from, time_to)

      end
    rescue Exception => e
      puts e.message
    end
  end
end
