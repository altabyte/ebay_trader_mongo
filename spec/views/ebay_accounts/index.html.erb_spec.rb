require 'rails_helper'

RSpec.describe 'ebay_accounts/index', type: :view do
  before(:each) do
    assign(:ebay_accounts, [
      EbayAccount.create!(
        :auth_token => 'Auth Token'
      ),
      EbayAccount.create!(
        :auth_token => 'Auth Token'
      )
    ])
  end

  it 'renders a list of ebay_accounts' do
    render
    assert_select 'tr>td', :text => 'Pending'.to_s, :count => 2
  end
end
