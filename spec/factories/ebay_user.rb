FactoryGirl.define do
  factory :ebay_user do
    sequence(:email)    { |n| "TESTUSER_#{n}@gmail.com" }
    sequence(:user_id)  { |n| "TESTUSER_#{n}" }
    feedback_score 1_000

    seller_info { FactoryGirl.build(:seller_info) }
  end


  factory :seller_info, class: EbayUser::SellerInfo do
    payment_method 'PayPal'
    store_owner false
  end
end