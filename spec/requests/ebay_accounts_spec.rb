require 'rails_helper'

RSpec.describe 'EbayAccounts', type: :request do

  after { User.all.delete }

  context 'when not signed in' do
    describe 'GET /ebay_accounts' do
      it 'Redirects us when not authenticated.' do
        get ebay_accounts_path
        expect(response).to have_http_status(302)
      end
    end
  end

  context 'when authenticated' do

    before { sign_in_as_a_valid_user }

    describe 'GET /ebay_accounts' do
      it 'works! (now write some real specs)' do
        get ebay_accounts_path
        expect(response).to have_http_status(200)
      end
    end
  end
end
