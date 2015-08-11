require 'ebay_trading_pack'
require 'ebay_trading_pack/get_user'
require 'mongoid_helpers/ebay_userable'

include EbayTradingPack

class GetUserWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  include EbayUserable

  # The current retry count is yielded. The return value of the block must be
  # an integer. It is used as the delay, in seconds.
  sidekiq_retry_in do |retry_count|
    (((retry_count + 1) ** 2) * 60)  # 1, 4, 9, 16, 25 then 36 minutes
  end

  def perform(auth_token, ebay_user_id)
    puts "\nRequesting details for eBay user: #{ebay_user_id}"

    get_user = EbayTradingPack::GetUser.new(auth_token, user_id: ebay_user_id)
    raise "Failed to get eBay user details for '#{ebay_user_id}'" if get_user.nil?
    raise get_user.errors.first[:short_message] if get_user.has_errors?

    find_or_create_ebay_user(get_user.user_hash, get_user.timestamp)
  end
end