class Offer
  attr_reader :price, :min, :max
  def initialize(price, min, max)
    @price, @min, @max = price, min, max
  end
end
