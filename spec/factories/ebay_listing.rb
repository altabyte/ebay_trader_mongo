FactoryGirl.define do
  factory :ebay_listing do
    site                  'UK'
    listing_type          'FixedPriceItem'
    title                 'eBay item title'
    sku                   'SKU1'
    quantity_listed       10
    item_id               123456789
    start_price           Money.new(10_00)
    listing_duration      EbayListing::GTC
    primary_category_id   164332
    hit_count             56

    listing_detail        { FactoryGirl.build(:listing_detail) }
    selling_state         { FactoryGirl.build(:selling_state) }
  end

  factory :listing_detail, class: EbayListing::ListingDetail do
    start_time            Time.now - 10.days
    end_time              Time.now + 10.days
    view_item_url         'http://www.ebay.co.uk/itm/Item-Title/123456789'
  end

  factory :selling_state, class: EbayListing::SellingState do
    current_price         Money.new(10_00)
    listing_state         'Active'
  end
end