require 'rails_helper'

RSpec.describe GetSellerListWorker do

  before :all do
    # Configure using PRODUCTION environment.
    # This is safe as we are only reading data from the server and not making any changes on eBay.
    # This can later be changed to Sandbox environment once AddItem API calls are implemented.
    configure_api_production

    @seller_user_id = ENV['EBAY_API_USERNAME_TT']
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TT']

    @seller = FactoryGirl.create :ebay_user, user_id: @seller_user_id

    # @TODO
    #
    #  ( -- UPLOAD SOME ITEMS HERE -- )  then use sandbox environment
    #
  end
  let(:auth_token) { @auth_token }
  let(:seller) { @seller }

  after :all do
    EbayListing.destroy_all
    EbayUser.destroy_all
  end

  # Check we are using PRODUCTION environment.
  it { expect(EbayTrader.configuration).to be_production }

  describe 'Seller' do
    it { expect(seller).not_to be_nil }
    it { expect(seller.ebay_listings.count).to eq(0) }
  end

  it { expect(GetSellerListWorker.new).to respond_to :perform }

  describe 'Perform' do
    before :all do
      page_number =  1
      per_page    = 10
      pipeline    = false
      GetSellerListWorker.new.perform(@auth_token, @seller_user_id, page_number, per_page, pipeline)
    end

    let(:listings) { seller.ebay_listings }

    it {
      expect(listings.count).to be > 0
      puts "Downloaded #{listings.count} eBay listings."
    }

    describe 'timestamps' do
      let(:listing) { listings.first }

      it { expect(listing.last_updated).not_to be_nil }
      it { expect(listing.last_updated).to be_a Time }
      it { puts "eBay item #{listing.item_id} last updated #{listing.last_updated}" }

      context 'when specifying call name for #last_updated' do
        it { expect(listing.last_updated('ABC')).to be_nil }
        it { expect(listing.last_updated('GetSellerList')).not_to be_nil }
        it { expect(listing.last_updated).to eq(listing.last_updated('GetSellerList')) }
      end
    end
  end
end
