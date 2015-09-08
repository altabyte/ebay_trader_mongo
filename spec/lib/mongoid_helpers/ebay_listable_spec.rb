require 'rails_helper'

require 'ebay_trader_support/get_item'
require 'mongoid_helpers/ebay_userable'
require 'mongoid_helpers/ebay_listable'

RSpec.describe EbayListable do
  include FileToString # Module located at end of spec_helper.rb
  include EbayUserable

  subject(:klass) { Class.new { extend EbayListable } }

  it { is_expected.not_to be_nil }
  it { is_expected.to respond_to :save }

  let(:auth_token) { ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1'] }
  let(:ebay_item_id) { 123456789 }
  let(:response_xml) do
    #self.file_to_string("#{__dir__}/../../xml_responses/get_item/#{ebay_item_id}.xml")
    self.file_to_string("#{__dir__}/../../xml_responses/get_item/variation_30_percent_sale.xml")
  end
  let(:get_item_request) do
    EbayTraderSupport::GetItem.new(ebay_item_id, xml_response: response_xml, auth_token: auth_token)
  end

  it { expect(get_item_request).not_to be_nil }
  it { expect(get_item_request).to be_success }

  describe 'save' do

    context 'When creating a new Listing' do

      after do
        cleanup = EbayListing.where(item_id: ebay_item_id)
        cleanup.destroy unless cleanup.nil?

        cleanup = EbayUser.all
        cleanup.destroy unless cleanup.nil?
      end

      it 'Creates a new ebay_listing' do
        expect{ EbayListing.find_by(item_id: ebay_item_id) }.to raise_error Mongoid::Errors::DocumentNotFound

        seller_hash = get_item_request.item_hash[:seller]
        seller = find_or_create_ebay_user(seller_hash, get_item_request.timestamp)

        expect(seller.ebay_listings).to be_empty

        klass.save(get_item_request, seller, EbayTraderSupport::GetItem::CALL_NAME, get_item_request.timestamp)
        expect{ EbayListing.find_by(item_id: ebay_item_id) }.not_to raise_error
        listing = EbayListing.find_by(item_id: ebay_item_id)

        expect(listing).not_to be_nil
        expect(listing.seller).not_to be_nil
        expect(listing.seller.id).to eq(seller.id)

        expect(seller.ebay_listings.count).to eq(1)

        puts "\n\n#{EbayListing.find_by(item_id: ebay_item_id).summary}\n\n"
      end

    end
  end
end