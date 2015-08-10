class EbayListing::ShippingServiceOption
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :shipping_service_optionable, polymorphic: true

  field :shipping_service, type: String
  field :shipping_service_cost, type: Money
  field :shipping_service_additional_cost, type: Money
  field :shipping_service_priority, type: Fixnum
  field :ship_to_locations, type: Array, default: []
end


class EbayListing::ShippingDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :ebay_listing

  embeds_many :international_shipping_service_options,
              as: :shipping_service_optionable,
              class_name: EbayListing::ShippingServiceOption.name
  accepts_nested_attributes_for :international_shipping_service_options

  embeds_many :shipping_service_options,
              as: :shipping_service_optionable,
              class_name: EbayListing::ShippingServiceOption.name
  accepts_nested_attributes_for :shipping_service_options

  field :apply_shipping_discount, type: Boolean, default: false

  field :exclude_ship_to_locations, type: Array, default: []

  field :international_shipping_discount_profile_id, type: Fixnum

  # Sellers can set up a global Exclude Ship-To List through their My eBay account.
  # The Exclude Ship-To List defines the countries to where the seller does not ship,
  # by default.
  #
  # This flag returns true if the Exclude Ship-To List is enabled by the seller for the
  # associated item. If false, the seller's Exclude Ship-To List is either not set up,
  # or it has been overridden by the seller when they listed the item with
  # +exclude_ship_to_locations+ fields.
  # @return [Boolean] +true+ if using seller account level exclude list.
  field :seller_exclude_ship_to_locations_preference, type: Boolean, default: false

  field :shipping_discount_profile_id, type: Fixnum
end