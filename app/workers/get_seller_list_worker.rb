require 'ebay_trader_support'
require 'ebay_trader_support/get_seller_list'
require 'mongoid_helpers/ebay_userable'
require 'mongoid_helpers/ebay_listable'

include EbayTraderSupport

class GetSellerListWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, dead: false

  # The current retry count is yielded. The return value of the block must be
  # an integer. It is used as the delay, in seconds.
  sidekiq_retry_in do |retry_count|
    (((retry_count + 1) ** 2) * 60)  # 1, 4, 9, 16, 25 then 36 minutes
  end

  include EbayUserable
  include EbayListable

  HTTP_TIMEOUT ||= 120 # seconds

  def perform(auth_token, seller_username, page_number = 1, per_page = 200, pipeline = true)

    begin
      seller = EbayUser.find_by(user_id: seller_username)
    rescue Mongoid::Errors::DocumentNotFound
      GetUserWorker.perform_async(auth_token, seller_username)
      raise "Seller details for '#{seller_username}' not available!"
    end

    number_of_pages = nil

    message = "# Getting page number #{page_number}"
    message << " of #{number_of_pages}" if number_of_pages
    puts message

    get_seller_list = GetSellerList.new(page_number, auth_token: auth_token, per_page: per_page, http_timeout: HTTP_TIMEOUT)
    raise get_seller_list.errors.first[:short_message] if get_seller_list.has_errors?
    number_of_pages = get_seller_list.total_number_of_pages

    # If we are currently on page 1 and +pipeline+ is true, queue workers to retrieve each other page of items...
    if page_number == 1 && number_of_pages > 1 && pipeline
      (2..number_of_pages).each do |page|
        GetSellerListWorker.perform_async(auth_token, seller_username, page, per_page, pipeline)
      end
    end

    get_seller_list.each do |item|
      puts "\n\n#{item.summary(true)}\n\n"
      save(item, seller, GetSellerList::CALL_NAME, get_seller_list.timestamp)
    end
  end
end