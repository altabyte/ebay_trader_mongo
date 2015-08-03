require 'rails_helper'

require 'ebay_trading_pack/get_item'
require 'mongoid_helpers/listing_document_helper'

RSpec.describe ListingDocumentHelper do
  include FileToString # Module located at end of spec_helper.rb

  subject(:klass) { Class.new { extend ListingDocumentHelper } }

  it { is_expected.not_to be_nil }
  it { is_expected.to respond_to :save }

  let(:auth_token) { ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1'] }
  let(:ebay_item_id) { 123456789 }
  let(:response_xml) do
    self.file_to_string("#{__dir__}/xml_responses/get_item/#{ebay_item_id}.xml")
  end
  let(:get_item_request) do
    EbayTradingPack::GetItem.new(auth_token, ebay_item_id, xml_response: response_xml)
  end

  it { expect(get_item_request).not_to be_nil }
  it { expect(get_item_request).to be_success }

  describe 'save' do

    context 'When creating a new Listing' do

      after do
        cleanup = Listing.where(item_id: ebay_item_id)
        cleanup.destroy unless cleanup.nil?
      end

      it 'Creates a new listing' do
        expect{ Listing.find_by(item_id: ebay_item_id) }.to raise_error Mongoid::Errors::DocumentNotFound
        klass.save(get_item_request, EbayTradingPack::GetItem::CALL_NAME, get_item_request.timestamp)
        expect{ Listing.find_by(item_id: ebay_item_id) }.not_to raise_error
      end

    end
  end
end