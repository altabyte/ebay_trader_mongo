FactoryGirl.define do

  factory :ebay_account do
    auth_token 'abcdefhijklmnopqrstuvwxyz'
    auth_token_expiry_time 1.year.from_now
  end
end