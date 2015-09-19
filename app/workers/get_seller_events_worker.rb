require 'ebay_trader_support'
require 'ebay_trader_support/get_seller_events'
require 'mongoid_helpers/ebay_userable'
require 'mongoid_helpers/ebay_listable'

include EbayTraderSupport

class GetSellerEventsWorker
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

  def perform(auth_token, event_type, time_from, time_to)
    seller = get_seller_ebay_user(auth_token)
    if seller
      event_type = event_type.to_s.downcase.to_sym
      time_from  = parse_time(time_from)
      time_to    = parse_time(time_to)
      puts "Getting seller events for '#{seller.user_id}' from #{time_from} until #{time_to}."

      events = GetSellerEvents.new(event_type, time_from, time_to, auth_token: auth_token, http_timeout: HTTP_TIMEOUT)
      raise events.errors.first.short_message if events.has_errors?

      events.each do |item|
        if EbayListing.where(item_id: item.item_id).exists?
          puts "\n\n#{item.summary(true)}\n\n"
          save(item, seller, GetSellerEvents::CALL_NAME, events.timestamp)
        else
          # Call GetItem for item.item_id ???
        end
      end
    end
  end

  #---------------------------------------------------------------------------
  private

  def get_seller_ebay_user(auth_token)
    begin
      EbayAccount.where(auth_token: auth_token).first.ebay_user
    rescue Exception
      nil
    end
  end

  def parse_time(time)
    begin
      Time.parse(time)
    rescue
      Time.now.utc
    end
  end
end
