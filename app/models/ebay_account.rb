class EbayAccount
  include Mongoid::Document

  belongs_to :user
  has_many :ebay_users, dependent: :nullify

  field :auth_token, type: String
  field :auth_token_expiry_time, type: Time

  validates :auth_token, presence: true
end
