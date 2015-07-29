# https://github.com/kristianmandrup/money-mongoid/blob/master/lib/money/mongoid/3x/money.rb

require 'money'

Money.default_currency = Money::Currency.new('GBP')

Money.add_rate('GBP', 'USD', 1.55)
Money.add_rate('USD', 'GBP', 0.64)
Money.add_rate('GBP', 'EUR', 1.41)
Money.add_rate('EUR', 'GBP', 0.71)

class Money
  def mongoize
    { 'cents' => cents, 'currency' => currency.iso_code }
  end

  # http://mongoid.org/en/mongoid/docs/documents.html
  class << self

    # Get the object as it was stored in the database, and instantiate a new Money object.
    def demongoize(object)
      object && ::Money.new(get_cents(object), get_currency(object))
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      case object
        when Money then object.mongoize
        when Hash then Money.new(object[:cents].to_i, object[:currency]).mongoize
        else object
      end
    end

    # Converts the object that was supplied to a criteria and converts it
    # into a database friendly form.
    def evolve(object)
      case object
        when Money then object.mongoize
        else object
      end
    end

    #-------------------------------------------------------------------------
    private

    def get_cents(value)
      value[:cents] || value['cents'] || value[:fractional] || value['fractional']
    end

    def get_currency(value)
      value[:currency] || value['currency']
    end
  end
end