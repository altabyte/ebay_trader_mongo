require 'ebay_trading_pack'
require 'ebay_trading_pack/get_user'
require 'mongoid_helpers/ebay_userable'


class LinkEbayUserAccountWorker
  include Sidekiq::Worker
  sidekiq_options retry: 2

  include EbayUserable

  # The current retry count is yielded. The return value of the block must be
  # an integer. It is used as the delay, in seconds.
  sidekiq_retry_in do |retry_count|
    (((retry_count + 1) ** 2) * 60)  # 1, 4, 9, 16, 25 then 36 minutes
  end

  def perform(ebay_account_id, auth_token)
    ebay_account = EbayAccount.find(BSON::ObjectId.from_string(ebay_account_id))
    get_user = EbayTradingPack::GetUser.new(auth_token)

    message = 'Pending'
    if get_user.nil?
      message = 'Failed to find eBay user from auth token'
    elsif get_user.has_errors?
      message = get_user.errors.first[:short_message]
    end

    ebay_account.ebay_user_status = message
    ebay_account.save!
    raise message unless message == 'Pending'

    ebay_user_id = get_user.user_id
    ebay_user = EbayUser.where(user_id: ebay_user_id).first_or_initialize
    ebay_user.update_attributes(get_user.user_hash)
    ebay_user.timestamp = get_user.timestamp

    ebay_account.ebay_user = ebay_user
    ebay_account.ebay_user_status = "Linked to eBay account '#{get_user.user_id}'"

    ebay_user.save!
    ebay_account.save!
  end
end
