require 'rails_helper'

RSpec.describe EbayListingController, type: :controller do

  let!(:user) { FactoryGirl.create(:user) }
  before { sign_in user }

  after {
    User.delete_all
    EbayListing.delete_all
  }

  describe 'GET #show' do

    it 'Redirects if no item_id' do
      get :show
      expect(response).to have_http_status(302)
    end

    it 'Redirects if item_id does not exist' do
      get :show, item_id: 12345
      expect(response).to have_http_status(302)
    end

    it 'returns http success' do
      item_id = 11223344
      FactoryGirl.create(:ebay_listing, item_id: item_id)
      get :show, item_id: item_id
      expect(response).to have_http_status(:success)
    end
  end

end
