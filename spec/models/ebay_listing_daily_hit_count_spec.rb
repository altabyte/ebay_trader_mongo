require 'rails_helper'

RSpec.describe EbayListingDailyHitCount, type: :model do

  after do
    EbayListing.destroy_all
    EbayUser.destroy_all
  end

  it { is_expected.to embed_many :hours }

  describe 'Create' do
    let(:ebay_listing) { FactoryGirl.create(:ebay_listing, hit_count: nil) }

    subject(:daily_hit_count) do
      EbayListingDailyHitCount.create(
          ebay_listing: ebay_listing,
          date: Date.today,
          sku: ebay_listing.sku,
          item_id: ebay_listing.item_id,
          seller: ebay_listing.seller)
    end

    it 'is valid' do
      expect(daily_hit_count).not_to be_nil
      expect(daily_hit_count).to be_valid
    end

    it 'has 0 opening balance' do
      expect(daily_hit_count.opening_balance).to eq(0)
    end

    it 'has 0 balance' do
      expect(daily_hit_count.closing_balance).to eq(0)
    end

    it 'closes with opening balance with no hourly hits' do
      daily_hit_count.opening_balance = 5_000
      daily_hit_count.save!
      expect(daily_hit_count.opening_balance).to eq(5_000)
      expect(daily_hit_count.closing_balance).to eq(5_000)
    end

    it 'captures the eBay listing details' do
      expect(daily_hit_count.sku).to eq(ebay_listing.sku)
      expect(daily_hit_count.item_id).to eq(ebay_listing.item_id)
    end

    it 'creates a list of 24 Hours' do
      expect(daily_hit_count.hours).to be_a(Array)
      expect(daily_hit_count.hours.count).to eq(24)
    end
  end

  describe '#hits' do
    let(:ebay_listing) { FactoryGirl.create(:ebay_listing, hit_count: nil) }
    let(:date) { Date.today }

    subject(:daily_hit_count) do
      EbayListingDailyHitCount.create(
          ebay_listing: ebay_listing,
          date: Date.today,
          sku: ebay_listing.sku,
          item_id: ebay_listing.item_id,
          seller: ebay_listing.seller)
    end

    it 'is valid' do
      expect(daily_hit_count).not_to be_nil
      expect(daily_hit_count).to be_valid
    end

    context 'when time is not on the same date' do
      it {
        expect {daily_hit_count.set_time_hit_count(10, date + 2.days)}.to raise_error(ArgumentError)
      }
    end

    context 'hit count is 0' do
      it { expect(daily_hit_count.set_time_hit_count(0, date.to_time)).to eq(0) }
      it { expect(daily_hit_count.closing_balance).to eq(0) }
    end

    context 'updating hits' do
      let(:opening_balance) { 5_000 }

      before do
        daily_hit_count.opening_balance = opening_balance
      end

      it 'adds hits' do
        balance = opening_balance
        balance += 21
        daily_hit_count.set_time_hit_count(balance, date.to_time + 1.hour + 10.minutes)
        expect(daily_hit_count.closing_balance).to eq(balance)
        expect(daily_hit_count.total_hits).to eq(balance - opening_balance)

        balance += 7
        daily_hit_count.set_time_hit_count(balance, date.to_time + 4.hours + 30.minutes)
        expect(daily_hit_count.closing_balance).to eq(balance)
        expect(daily_hit_count.total_hits).to eq(balance - opening_balance)

        # Assign the same value to hits within the same hour.
        daily_hit_count.set_time_hit_count(balance, date.to_time + 4.hours + 31.minutes)
        expect(daily_hit_count.closing_balance).to eq(balance)
        expect(daily_hit_count.total_hits).to eq(balance - opening_balance)

        balance += 1
        daily_hit_count.set_time_hit_count(balance, date.to_time + 4.hours + 32.minutes)
        expect(daily_hit_count.closing_balance).to eq(balance)
        expect(daily_hit_count.total_hits).to eq(balance - opening_balance)

        balance += 102
        daily_hit_count.set_time_hit_count(balance, date.to_time + 21.hours + 59.minutes)
        expect(daily_hit_count.closing_balance).to eq(balance)
        expect(daily_hit_count.total_hits).to eq(balance - opening_balance)

        puts
        puts "#{daily_hit_count.date} had a total of #{daily_hit_count.total_hits} hits for eBay item #{daily_hit_count.item_id} [#{daily_hit_count.sku}]"
        daily_hit_count.hours.each do |hour|
          puts "  #{hour.hour.to_s.rjust(2, '0')}  ->  #{hour.hits.to_s.rjust(4)}  [#{daily_hit_count.hour_balance(hour.hour)}]"
        end
      end

      it 'ignores balances less than opening balance' do
        daily_hit_count.set_time_hit_count(opening_balance - 50, date.to_time + 1.hour + 10.minutes)
        expect(daily_hit_count.closing_balance).to eq(opening_balance)
      end
    end
  end

end
