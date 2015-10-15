require 'rails_helper'

RSpec.describe EbayListingDailyHitCount, type: :model do

  after do
    EbayListing.destroy_all
  end

  it { is_expected.to embed_many :hours }

  describe 'Create' do
    let(:ebay_listing) { FactoryGirl.create(:ebay_listing, hit_count: nil) }

    subject(:hit_count) { EbayListingDailyHitCount.create(ebay_listing: ebay_listing, date: Date.today) }

    it 'is valid' do
      expect(hit_count).not_to be_nil
      expect(hit_count).to be_valid
    end

    it 'has 0 opening balance' do
      expect(hit_count.opening_balance).to eq(0)
    end

    it 'has 0 balance' do
      expect(hit_count.closing_balance).to eq(0)
    end

    it 'closes with opening balance with no hourly hits' do
      hit_count.opening_balance = 5_000
      hit_count.save!
      expect(hit_count.opening_balance).to eq(5_000)
      expect(hit_count.closing_balance).to eq(5_000)
    end

    it 'captures the eBay listing details' do
      expect(hit_count.sku).to eq(ebay_listing.sku)
      expect(hit_count.item_id).to eq(ebay_listing.item_id)
    end

    it 'creates a list of 24 Hours' do
      expect(hit_count.hours).to be_a(Array)
      expect(hit_count.hours.count).to eq(24)
    end
  end

  describe '#hits' do
    let(:ebay_listing) { FactoryGirl.create(:ebay_listing, hit_count: nil) }
    let(:date) { Date.today }

    subject(:hit_count) { EbayListingDailyHitCount.create(ebay_listing: ebay_listing, date: date) }

    context 'when time is not on the same date' do
      it { expect {hit_count.set_time_hit_count(10, date + 2.days)}.to raise_error(ArgumentError) }
    end

    context 'hit count is 0' do
      it { expect(hit_count.set_time_hit_count(0, date.to_time)).to eq(0) }
      it { expect(hit_count.closing_balance).to eq(0) }
    end

    context 'updating hits' do
      let(:opening_balance) { 5_000 }

      before do
        hit_count.opening_balance = opening_balance
      end

      it 'adds hits' do
        balance = opening_balance
        balance += 21
        hit_count.set_time_hit_count(balance, date.to_time + 1.hour + 10.minutes)
        expect(hit_count.closing_balance).to eq(balance)
        expect(hit_count.total_hits).to eq(balance - opening_balance)

        balance += 7
        hit_count.set_time_hit_count(balance, date.to_time + 4.hours + 30.minutes)
        expect(hit_count.closing_balance).to eq(balance)
        expect(hit_count.total_hits).to eq(balance - opening_balance)

        # Assign the same value to hits within the same hour.
        hit_count.set_time_hit_count(balance, date.to_time + 4.hours + 31.minutes)
        expect(hit_count.closing_balance).to eq(balance)
        expect(hit_count.total_hits).to eq(balance - opening_balance)

        balance += 1
        hit_count.set_time_hit_count(balance, date.to_time + 4.hours + 32.minutes)
        expect(hit_count.closing_balance).to eq(balance)
        expect(hit_count.total_hits).to eq(balance - opening_balance)

        balance += 102
        hit_count.set_time_hit_count(balance, date.to_time + 21.hours + 59.minutes)
        expect(hit_count.closing_balance).to eq(balance)
        expect(hit_count.total_hits).to eq(balance - opening_balance)

        puts
        puts "#{hit_count.date} had a total of #{hit_count.total_hits} hits for eBay item #{hit_count.item_id} [#{hit_count.sku}]"
        hit_count.hours.each do |hour|
          puts "  #{hour.hour.to_s.rjust(2, '0')}  ->  #{hour.hits.to_s.rjust(4)}  [#{hit_count.hour_balance(hour.hour)}]"
        end
      end
    end
  end

end
