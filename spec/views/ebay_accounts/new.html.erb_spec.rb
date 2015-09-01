require 'rails_helper'

RSpec.describe 'ebay_accounts/new', type: :view do

  let!(:user) { FactoryGirl.create(:user) }

  before(:each) do
    @ebay_account = assign(:ebay_account, FactoryGirl.build(:ebay_account, user: user))
  end

  after do
    User.all.delete
    EbayAccount.all.delete
  end

  it 'renders new ebay_account form' do
    render

    assert_select 'form[action=?][method=?]', ebay_accounts_path, 'post' do
      assert_select 'textarea#ebay_account_auth_token[name=?]', 'ebay_account[auth_token]'
    end
  end
end
