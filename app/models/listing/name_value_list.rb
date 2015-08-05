class Listing::NameValueList
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :name_value_list_container

  field :name, type: String
  field :value, type: Array, default: []
  field :source, type: String

  validates :name, presence: true

  def value=(array)
    array = [array] unless array.is_a? Array
    array.map! { |element| element.to_s }
    self[:value] = array
  end

  def value
    case self[:value].count
      when 0 then return nil
      when 1 then return self[:value].first
      else
        return self[:value]
    end
  end
end