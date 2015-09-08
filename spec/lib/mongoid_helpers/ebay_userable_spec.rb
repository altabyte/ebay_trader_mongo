require 'rails_helper'

require 'ebay_trader_support/get_user'
require 'mongoid_helpers/ebay_userable'

RSpec.describe EbayUserable do

  let(:klass) { Class.new { extend EbayUserable } }

  after do
    cleanup = EbayUser.all
    cleanup.destroy unless cleanup.nil?
  end

  it { expect(klass).not_to be_nil }
  it { expect(klass).to respond_to :find_or_create_ebay_user }

  context 'When requesting user details for the API request caller' do

    before :all do
      auth_token = ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1']
      @get_user = EbayTraderSupport::GetUser.new(auth_token: auth_token)
    end

    let(:user) { @get_user }
    let(:user_id) { user.user_id }
    let(:user_hash) { user.user_hash }
    let(:timestamp) { user.timestamp }

    it 'should successfully retrieve user details' do
      expect(user).not_to be_nil
      expect(user).to be_success
      puts user.user_hash.to_yaml
    end

    it { expect(user_id).not_to be_nil }

    it 'Creates a new eBay user' do
      expect{ EbayUser.find_by(user_id: user_id) }.to raise_error Mongoid::Errors::DocumentNotFound
      klass.find_or_create_ebay_user(EbayUser.restructure_hash(user_hash), timestamp)
      expect{ EbayUser.find_by(user_id: user_id) }.not_to raise_error
    end

    it 'Finds the correct user if they already exist' do
      expect(EbayUser.count).to eq(0)
      klass.find_or_create_ebay_user(EbayUser.restructure_hash(user_hash), timestamp)
      expect(EbayUser.count).to eq(1)
      klass.find_or_create_ebay_user(EbayUser.restructure_hash(user_hash), timestamp)
      expect(EbayUser.count).to eq(1)
    end

    it 'Prevents the email address from being nullified' do
      ebay_user = klass.find_or_create_ebay_user(EbayUser.restructure_hash(user_hash), timestamp)
      expect(ebay_user).not_to be_nil
      expect(ebay_user.email).not_to be_nil
      new_email = 'new@email.com'
      ebay_user.email = new_email
      expect(ebay_user.email).to eq(new_email)
      ebay_user.email = nil
      expect(ebay_user.email).not_to be_nil
      expect(ebay_user.email).to eq(new_email)
      ebay_user.email = 'Invalid Request'
      expect(ebay_user.email).to eq(new_email)
      new_email_2 = 'new_2@email.com'
      ebay_user.email = new_email_2
      expect(ebay_user.email).to eq(new_email_2)
    end
  end
end