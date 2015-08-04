require 'rails_helper'

RSpec.describe Listing, type: :model do

  let(:ebay_item_id)  { 123456789 }

  after do
    cleanup = Listing.where(item_id: 123456789)
    cleanup.destroy unless cleanup.nil?
  end

  context 'When creating a new listing from a Raw Hash' do
    let(:sku)   { 'SKU1' }
    let(:title) { 'eBay item title' }
    let(:hash) {
      {
          seller_username:        'seller_1',
          site:                   'UK',
          listing_type:           'FixedPriceItem',
          sku:                    sku,
          quantity_listed:        10,
          item_id:                ebay_item_id,
          title:                  title,
          currency:               'GBP',
          start_price:            Money.new(12_99),
          listing_duration:       Listing::GTC,
          primary_category_id:    164332,

          listing_detail: {
              start_time:         Time.now - 10.days,
              end_time:           Time.now + 10.days,
              view_item_url:      "http://www.ebay.co.uk/itm/#{title.downcase.gsub(/\s+/, '-')}/#{sku}"
          }
      }
    }

    subject(:listing) { Listing.new(hash) }

    it { is_expected.not_to be_nil }
    it { is_expected.to be_valid }
    it { expect(listing.save).to be true }
    it { listing.save; expect(Listing.count).to eq(1) }
    it 'should have the values defined in the constructor hash' do
      expect(listing.sku).to eq(sku)
      expect(listing.item_id).to eq(ebay_item_id)
      expect(listing.title).to eq(title)
    end


    context 'Listing Details' do
      it { expect(listing).to embed_one :listing_detail }
      it { expect(listing.listing_detail).not_to be_nil }
      it { expect(listing.listing_detail.end_time).to be > Time.now }
    end

    # Test Mongoid::Attributes::Dynamic
    context 'When initial hash has fields not defined in the model' do
      let(:undefined_field_value) { 'my unknown field data' }
      let(:hash_2) { hash.merge(undefined_field: undefined_field_value) }
      subject(:listing) { Listing.create(hash_2) }
      it { is_expected.not_to be_nil }
      it { is_expected.to respond_to :undefined_field }
      it { expect(listing.undefined_field).to eq(undefined_field_value) }
    end

    context 'When no best offer added' do
      it { expect(listing.best_offer_detail).to be_nil }
      it { expect(listing).not_to have_best_offer }
    end

    context 'When best offer enabled' do
      let(:best_offer_detail) { { best_offer_enabled: true } }
      subject(:listing) { Listing.create(hash.merge(best_offer_detail: best_offer_detail)) }

      it { expect(listing.best_offer_detail).not_to be_nil }

      it 'responds to field name aliases with ? appended' do
        expect(listing.best_offer_detail).to respond_to :best_offer_enabled
        expect(listing.best_offer_detail).to respond_to :best_offer_enabled?
        expect(listing.best_offer_detail).to respond_to :new_best_offer
        expect(listing.best_offer_detail).to respond_to :new_best_offer?
      end
      it { expect(listing.best_offer_detail).to be_best_offer_enabled }
      it { expect(listing.best_offer_detail).not_to be_new_best_offer }
      it { expect(listing.best_offer_detail.best_offer_count).to eq(0) }

      it { expect(listing).to have_best_offer }
    end
  end


  context 'FactoryGirl listing' do
    let(:sku) { 'ABC123' }
    subject (:listing) { FactoryGirl.create(:listing, item_id: ebay_item_id, sku: sku) }

    it { is_expected.not_to be_nil }
    it { listing; expect(Listing.count).to eq(1) }

    it { expect(listing.sku).to eq(sku) }
    it { is_expected.to have_index_for(item_id: 1).with_options(unique: true) }
    it { is_expected.to validate_presence_of(:sku) }
    it { is_expected.to validate_presence_of(:title) }

    it 'should have a Money start price' do
      listing.reload
      expect(listing.start_price).not_to be_nil
      expect(listing.start_price).to be_a(Money)
      expect(listing.start_price.currency).to eq('GBP')
      puts "Start Price: #{listing.start_price.symbol}#{listing.start_price}"
      usd = listing.start_price.exchange_to('USD')
      puts "             #{usd.symbol}#{usd}"
      eur = listing.start_price.exchange_to('EUR')
      puts "             #{eur.symbol}#{eur}"

      expect(listing[:start_price]).to be_a(Hash)
      expect(listing[:start_price]).to have_key('cents')
      expect(listing[:start_price]).to have_key('currency')
    end


    describe 'ListingDetails' do
      it { expect(listing).to embed_one :listing_detail }
      subject(:details) { listing.listing_detail }

      it { is_expected.not_to be_nil }
      it { expect(details.start_time).to be < Time.now }
      it { expect(details.end_time).to be > Time.now }
      it { expect(details.view_item_url).to match /^http:\/\/www.ebay.co.uk\/itm\// }

      it { is_expected.to validate_presence_of(:start_time) }
      it { is_expected.to validate_presence_of(:end_time) }

      it { expect(details.has_unanswered_questions).to be false }
      it { expect(details.has_public_messages).to be false }
    end
  end

end
