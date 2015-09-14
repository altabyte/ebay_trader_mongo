require 'rails_helper'

RSpec.describe 'ebay_accounts/index', type: :view do
  before(:each) do
    assign(:ebay_accounts, [
      EbayAccount.create!(
        :auth_token => 'Auth Token 1'
      ),
      EbayAccount.create!(
        :auth_token => 'Auth Token 2'
      )
    ])
  end

  after(:each) do
    EbayAccount.delete_all
  end

  it 'renders a list of ebay_accounts' do
    render
    assert_select 'div>a', :text => 'Pending'.to_s, :count => 2
  end
end
