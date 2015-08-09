module EbayUserable

  def find_or_create_ebay_user(user_hash, timestamp)
    raise 'Cannot find or create user from invalid hash' unless user_hash.is_a?(Hash) && user_hash.key?(:user_id)
    user_id = user_hash[:user_id]

    user_hash[:timestamp] = timestamp

    begin
      user = EbayUser.find_by(user_id: user_id)
      if timestamp && timestamp > user.timestamp
        user.update_attributes(user_hash)
      end
    rescue Mongoid::Errors::DocumentNotFound
      user = EbayUser.create!(user_hash)
    end
    user
  end
end