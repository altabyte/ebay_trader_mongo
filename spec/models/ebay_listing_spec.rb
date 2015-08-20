require 'rails_helper'

RSpec.describe EbayListing, type: :model do

  let(:ebay_item_id)  { 123456789 }

  after do
    cleanup = EbayListing.where(item_id: 123456789)
    cleanup.destroy unless cleanup.nil?
  end

  context 'When creating a new ebay_listing from a Raw Hash' do
    let(:sku)   { 'SKU1' }
    let(:title) { 'eBay item title' }
    let(:timestamp) { Time.now.utc }
    let(:hash) {
      {
          seller_username:        'TESTUSER_seller_1',
          site:                   'UK',
          listing_type:           'FixedPriceItem',
          sku:                    sku,
          quantity_listed:        10,
          item_id:                ebay_item_id,
          title:                  title,
          currency:               'GBP',
          start_price:            Money.new(12_99),
          listing_duration:       EbayListing::GTC,
          primary_category_id:    164332,

          listing_detail: {
              start_time:         Time.now - 10.days,
              end_time:           Time.now + 10.days,
              view_item_url:      "http://www.ebay.co.uk/itm/#{title.downcase.gsub(/\s+/, '-')}/#{sku}"
          },

          selling_state: {
            current_price:        Money.new(12_99),
            listing_state:        'Active'
          }
      }
    }

    subject(:listing) do
      listing = EbayListing.new(hash)
      listing.add_timestamp 'GetItem', timestamp
      listing.save
      listing
    end

    it { is_expected.not_to be_nil }
    it { is_expected.to be_valid }
    it { expect(listing.save).to be true }
    it { listing.save; expect(EbayListing.count).to eq(1) }
    it 'should have the values defined in the constructor hash' do
      expect(listing.sku).to eq(sku)
      expect(listing.item_id).to eq(ebay_item_id)
      expect(listing.title).to eq(title)
    end

    # Test Mongoid::Attributes::Dynamic
    context 'When initial hash has fields not defined in the model' do
      let(:undefined_field_value) { 'my unknown field data' }
      let(:hash_2) { hash.merge(undefined_field: undefined_field_value) }
      subject(:listing) { EbayListing.create(hash_2) }
      it { is_expected.not_to be_nil }
      it { is_expected.to respond_to :undefined_field }
      it { expect(listing.undefined_field).to eq(undefined_field_value) }
    end


    describe 'ListingDetail' do
      subject(:detail) { listing.listing_detail }

      it { expect(listing).to embed_one :listing_detail }
      it { expect(detail).not_to be_nil }
      it { expect(detail.start_time).to be < Time.now }
      it { expect(detail.end_time).to be > Time.now }
      it { expect(detail.days_active).to eq(11) }
      it { expect(detail.relisted_item_id).to be_nil }
      it { expect(detail).not_to have_reserve_price }
      it { expect(detail).not_to have_unanswered_questions }
      it { expect(detail).not_to have_public_messages }
    end


    describe 'SellingState' do
      subject(:state) { listing.selling_state }

      it { expect(listing).to embed_one :selling_state }
      it { expect(state).not_to be_nil }
      it { expect(state).to be_valid }
      it { expect(state.current_price).to be_a Money }
      it { expect(state.listing_state).not_to be_nil }
      it { expect(state).not_to have_promotion }
      it { expect(state).not_to be_on_sale_now }
      it { expect(listing).not_to be_on_sale_now }

      context 'When on promotional sale' do
        let(:sale_percentage) { 30 }
        let(:original_price) { listing.start_price }
        let(:sale_price) { original_price - (original_price / 100 * sale_percentage) }
        let(:promotional_sale_detail) do
          {
              start_time:     Time.now - 1.day,
              end_time:       Time.now + 1.day,
              original_price: original_price
          }
        end
        let(:promotion) { listing.selling_state.promotional_sale_detail }

        before do
          listing.start_price = sale_price
          listing.selling_state.current_price = sale_price
          listing.selling_state.promotional_sale_detail = promotional_sale_detail
        end

        it { expect(state.promotional_sale_detail).to be_valid }
        it { expect(listing.start_price).to eq(sale_price) }
        it 'Has 30% off now' do
          expect(state).to have_promotion
          expect(state).to be_on_sale_now
          expect(promotion).to be_on_sale_now
          expect(promotion.percentage_discount).to eq(30)
          puts "Promotion start time:   #{promotion.start_time}"
          puts "Promotion end time:     #{promotion.end_time}"
          puts "Original Price:         #{promotion.original_price.symbol}#{promotion.original_price}"
          puts "Sale Price:             #{promotion.sale_price.symbol}#{promotion.sale_price}"
          puts "Percentage discount:    #{promotion.percentage_discount}%"
        end

        context 'After a promotion has finished' do
          it 'Removes the PromotionalSaleDetail' do
            state.promotional_sale_detail = nil
            expect(listing.save).to be true
            expect(state).not_to have_promotion
          end
        end
      end
    end


    describe 'Best Offers' do

      context 'When no best offer added' do
        it { expect(listing.best_offer_detail).to be_nil }
        it { expect(listing).not_to have_best_offer }

        it { expect(listing.listing_detail.best_offer_auto_accept_price).to be_nil }
        it { expect(listing.listing_detail.minimum_best_offer_price).to be_nil }
      end

      context 'When best offer enabled' do
        let(:best_offer_detail) { { best_offer_enabled: true } }
        subject(:listing) {
          best_offer_hash = hash.merge(best_offer_detail: best_offer_detail)
          list_detail = hash[:listing_detail]
          list_detail[:best_offer_auto_accept_price] = Money.new(9_99)
          list_detail[:minimum_best_offer_price]     = Money.new(7_99)
          listing = EbayListing.new(best_offer_hash)
          listing.add_timestamp 'GetItem', timestamp
          listing.save
          listing.reload
        }

        it { expect(listing).to embed_one :best_offer_detail }
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

        it { expect(listing.listing_detail.best_offer_auto_accept_price).to be_a Money }
        it { expect(listing.listing_detail.minimum_best_offer_price).to be_a Money }
      end
    end


    describe 'ItemSpecifics' do

      it { expect(listing).to embed_many :item_specifics }

      context 'Before any item specifics are added' do
        it { expect(listing.item_specifics).to be_a(Array) }
        it { expect(listing.item_specifics).to be_empty }
      end

      context 'Adding item specifics' do
        let(:item_specifics_hash) do
          [
            {
                name_value_lists: [
                    { name: 'Main Stone', value: ['Lapis'] },
                    { name: 'Color',      value: 'Blue' },
                    { name: 'Length',     value: 19 },
                    { name: 'Theme',      value: ['Fashion Tips', 'Beauty']}
                ]
            }
          ]
        end
        let(:hash_with_item_specifics) { hash_with_item_specifics = hash.merge(item_specifics: item_specifics_hash) }
        subject(:listing) do
          listing = EbayListing.new(hash_with_item_specifics)
          listing.add_timestamp 'GetItem', timestamp
          listing.save
          listing
        end

        it { puts hash_with_item_specifics.to_yaml }
        it { expect(listing.item_specifics.count).to eq(1) }
        it { expect(listing.item_specifics.first).to be_a(EbayListing::NameValueListContainer) }

        it 'should return the value corresponding to name' do
          listing.reload
          expect(listing.item_specifics[0].value_for('Main Stone')).to eq('Lapis')
          expect(listing.item_specifics[0].value_for('main stone')).to eq('Lapis')
          expect(listing.item_specifics[0].value_for(:main_stone)).to eq('Lapis')
          expect(listing.item_specifics[0].value_for('Color')).to eq('Blue')
          expect(listing.item_specifics[0].value_for('Length')).to eq('19') # String not Fixnum!
          expect(listing.item_specifics[0].value_for('Theme')).to be_a(Array)
          expect(listing.item_specifics[0].value_for('Theme').count).to eq(2)
          expect(listing.item_specifics[0].value_for('UNDEFINED')).to be_nil
          expect(listing.item_specifics[0].value_for(nil)).to be_nil
          expect(listing.item_specifics[0].value_for(123)).to be_nil
        end

        it 'collects a list of all key names' do
          names = listing.item_specifics.first.names
          expect(names).not_to be_nil
          expect(names).to be_a Array
          expect(names.count).to eq(4)
          puts names.join(', ')
        end
      end
    end
  end



  context 'FactoryGirl ebay_listing' do
    let(:sku) { 'ABC123' }
    let(:hit_count) { 321 }
    let(:timestamp) { Time.now.utc }
    subject (:ebay_listing) do
      listing = FactoryGirl.build(:ebay_listing,
                                  item_id: ebay_item_id,
                                  sku: sku,
                                  hit_count: hit_count)
      listing.add_timestamp 'GetItem', timestamp
      listing.save
      listing
    end

    it { is_expected.not_to be_nil }
    it { is_expected.to be_valid }
    it { ebay_listing; expect(EbayListing.count).to eq(1) }
    it { expect(ebay_listing.sku).to eq(sku) }
    it { is_expected.to have_index_for(item_id: 1).with_options(unique: true) }
    it { is_expected.to validate_presence_of(:sku) }
    it { is_expected.to validate_presence_of(:title) }


    describe 'Timestamps' do
      it { expect(ebay_listing).to embed_many :timestamps }
      it { expect(ebay_listing.timestamps).not_to be_empty }
      it { expect(ebay_listing.last_updated).not_to be_nil }

      it 'adds a timestamp' do
        timestamp_count = ebay_listing.timestamps.count
        expect(ebay_listing.add_timestamp('GetSellerList', Time.now)).to be true
        expect(ebay_listing.timestamps.size).to eq(timestamp_count + 1)
        expect(ebay_listing.timestamps.last).to be_valid
      end

      it 'fails to add a timestamp with an invalid call name' do
        timestamp_count = ebay_listing.timestamps.count
        expect(ebay_listing.add_timestamp('INVALID_NAME', Time.now)).to be false
        expect(ebay_listing.timestamps.count).to eq(timestamp_count)
      end

      it 'sorts timestamps' do
        times = [Time.now.utc, Time.now.utc + 1.days, Time.now.utc - 1.days, Time.now.utc - 2.hours]
        times.each { |time| ebay_listing.add_timestamp 'GetSellerList', time }

        # Need to save then reload for ordering
        expect(ebay_listing.save).to be true
        ebay_listing.reload

        expect(ebay_listing.timestamps.count).to eq(times.count + 1)
        expect(ebay_listing.timestamps.last.time.to_i).to eq(times[1].to_i)

        # Check times are in ascending order
        (1...ebay_listing.timestamps.count).each do |i|
          expect(ebay_listing.timestamps[i-1].time).to be < ebay_listing.timestamps[i].time
        end

        expect(ebay_listing.last_updated.to_i).to eq(times[1].to_i)
      end
    end


    describe 'Hits' do
      it { expect(ebay_listing.hit_count).to eq(hit_count) }

      it { expect(ebay_listing).to have_many :hits }
      it { expect(ebay_listing.hits).not_to be_empty }
      it { expect(ebay_listing.hits.size).to eq(1) }
      it { expect(ebay_listing.hits.last.count).to eq(ebay_listing.hit_count) }

      it { expect(ebay_listing.hits.last.sku).to eq(sku) }
      it { expect(ebay_listing.hits.last.item_id).to eq(ebay_listing.item_id) }
      it { expect(ebay_listing.hits.last.on_sale).to eq(ebay_listing.on_sale_now?) }

      describe 'updating hit_count' do
        let(:new_hit_count) { ebay_listing.hit_count + 5 }

        it 'adds a new Hit' do
          ebay_listing.hit_count = new_hit_count
          expect(ebay_listing.save).to be true
          ebay_listing.reload
          expect(ebay_listing.hit_count).to eq(new_hit_count)

          expect(ebay_listing.hits.size).to eq(2)
          expect(ebay_listing.hits.last.count).to eq(new_hit_count)
        end

        it 'does not add a new Hit if hit_count is unchanged' do
          ebay_listing.hit_count = hit_count
          expect(ebay_listing.save).to be true
          ebay_listing.reload
          expect(ebay_listing.hits.size).to eq(1)
          expect(ebay_listing.hits.last.count).to eq(hit_count)
        end
      end
    end


    describe 'start_price' do
      it 'should have a Money start price' do
        ebay_listing.reload
        expect(ebay_listing.start_price).not_to be_nil
        expect(ebay_listing.start_price).to be_a(Money)
        expect(ebay_listing.start_price.currency).to eq('GBP')
        puts "Start Price: #{ebay_listing.start_price.symbol}#{ebay_listing.start_price}"
        usd = ebay_listing.start_price.exchange_to('USD')
        puts "             #{usd.symbol}#{usd}"
        eur = ebay_listing.start_price.exchange_to('EUR')
        puts "             #{eur.symbol}#{eur}"

        expect(ebay_listing[:start_price]).to be_a(Hash)
        expect(ebay_listing[:start_price]).to have_key('cents')
        expect(ebay_listing[:start_price]).to have_key('currency')
      end
    end


    describe 'ListingDetails' do
      it { expect(ebay_listing).to embed_one :listing_detail }
      subject(:details) { ebay_listing.listing_detail }

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
