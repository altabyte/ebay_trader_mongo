class EbayUser
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  belongs_to :ebay_account
  has_many :ebay_listings, dependent: :nullify

  embeds_one :seller_info, class_name: EbayUser::SellerInfo.name

  # The timestamp returned by the eBay API request.
  # This should be checked before each update to ensure that older
  # data never overwrites information from more recent calls.
  # @return [Time] the timestamp of the last update.
  field :timestamp, type: Time

  field :ebay_good_standing, type: Boolean, default: false
  field :ebay_subscriptions, type: Array, default: []
  field :email, type: String
  field :enterprise_seller, type: Boolean, default: false
  field :feedback_score, type: Fixnum, default: 0
  field :motors_dealer, type: Boolean, default: false
  field :new_user, type: Boolean, default: false
  field :registration_date, type: Time
  field :site, type: String
  field :status, type: String
  field :user_id, type: String
  field :user_id_changed, type: Boolean, default: false
  field :user_id_last_changed, type: Time
  field :user_subscription, type: Array, default: []
  field :unique_negative_feedback_count, type: Fixnum, default: 0
  field :unique_neutral_feedback_count,  type: Fixnum, default: 0
  field :unique_positive_feedback_count, type: Fixnum, default: 0

  validates :user_id, uniqueness: true
  validates :email, uniqueness: true

  index({ user_id: 1 }, { unique: true, name: 'user_id_index' })
  index({ email:   1 }, { unique: true, name: 'email_index' })

  # Prevent any currently held email address for a user from being
  # nullified. Currently eBay only returns customer email addresses
  # if the transaction was within 45 days.
  # @param [String] email the eBay user email address.s
  def email=(email)
    email = nil if email =~ /Invalid Request/i
    self[:email] = email unless email.blank?
  end


  # Restructure the given hash of user details so that it is more compatible with
  # MongoDB.
  #
  # @param [Hash] user_hash the Hash of user data created by EbayTradingPack::GetUser
  #
  # @return the same hash with some fields modified for this application.
  #
  def self.restructure_hash(user_hash)

    user_hash.deep_transform_keys! do |key|
      key = 'ebay_subscriptions' if key == 'ebay_subscription'
      key = 'sites' if key == 'site'
      key = 'top_rated_programs' if key == 'top_rated_program'
      key = 'user_subscriptions' if key == 'user_subscription'
      key
    end

    if user_hash.key?(:top_rated_seller_details) && user_hash[:top_rated_seller_details].key?(:top_rated_programs)
      user_hash[:top_rated_programs] = user_hash[:top_rated_seller_details][:top_rated_programs]
      user_hash.delete(user_hash[:top_rated_seller_details])
    end

    user_hash
  end
end