class Listing::NameValueListContainer
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # @return [Listing] the listing to which these details belong.
  embedded_in :name_value_list_containable, polymorphic: true

  embeds_many :name_value_lists,
              as: :name_value_listable,
              class_name: 'Listing::NameValueList'

  def count
    name_value_lists.count
  end

  def names
    array = []
    name_value_lists.each { |name_value_list| array << name_value_list.name unless array.include?(name_value_list.name) }
    array.sort
  end

  def value_for(key)
    return nil if key.blank?
    key = key.to_s.strip.gsub(/[_]+/, ' ')
    key = Regexp.escape(key)  # Sanitize as name could contain user input.
    name_value_lists.each { |name_value_list| return name_value_list.value if name_value_list.name =~ /#{key}/i }
    nil
  end
end