FactoryGirl.define do
  factory :ebay_user do
    email 'TESTUSER_1@email.com'
    user_id 'TESTUSER_1'
    feedback_score 1_000

    seller_info { FactoryGirl.build(:seller_info) }
  end


  factory :seller_info, class: EbayUser::SellerInfo do
    payment_method 'PayPal'
    store_owner false
  end
end