FactoryGirl.define do
  factory :listing do
    title           'eBay item title'
    sku             'SKU1'
    item_id         123456789
    start_price     Money.new(10_00)

    listing_detail  { FactoryGirl.build(:listing_detail) }
  end

  factory :listing_detail, :class => Listing::ListingDetail do
    start_time    Time.now - 10.days
    end_time      Time.now + 10.days
    view_item_url 'http://www.ebay.co.uk/itm/Item-Title/123456789'
  end
end