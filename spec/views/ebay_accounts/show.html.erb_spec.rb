require 'rails_helper'

RSpec.describe 'ebay_accounts/show', type: :view do
  before(:each) do
    @ebay_account = assign(:ebay_account, EbayAccount.create!(
      :auth_token => 'Auth Token'
    ))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/Auth Token/)
  end
end
