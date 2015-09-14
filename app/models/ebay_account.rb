class EbayAccount
  include Mongoid::Document

  belongs_to :user
  has_one :ebay_user, dependent: :nullify

  field :ebay_user_status, type: String, default: 'Pending'

  field :auth_token, type: String
  field :auth_token_expiry_time, type: Time

  validates :auth_token, presence: true, uniqueness: true
end
