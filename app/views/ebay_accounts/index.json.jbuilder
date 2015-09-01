json.array!(@ebay_accounts) do |ebay_account|
  json.extract! ebay_account, :id, :auth_token, :auth_token_expiry_time
  json.url ebay_account_url(ebay_account, format: :json)
end
