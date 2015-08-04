FactoryGirl.define do
  factory :listing do
    seller_username       'seller_1'
    site                  'UK'
    listing_type          'FixedPriceItem'
    title                 'eBay item title'
    sku                   'SKU1'
    quantity_listed       10
    item_id               123456789
    start_price           Money.new(10_00)
    listing_duration      Listing::GTC
    primary_category_id   164332


    listing_detail  { FactoryGirl.build(:listing_detail) }
  end

  factory :listing_detail, :class => Listing::ListingDetail do
    start_time    Time.now - 10.days
    end_time      Time.now + 10.days
    view_item_url 'http://www.ebay.co.uk/itm/Item-Title/123456789'
  end
end