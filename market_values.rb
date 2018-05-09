require "./offer"

class MarketValues
  attr_reader :cur_prices

  def initialize(driver, purchase_difference = 5, match_other_bids = false)
    @driver = driver
    @purchase_above_difference = purchase_difference
    @match_other_bids = match_other_bids
  end

  def update_prices
    @prev_prices = @cur_prices
    update_cur_prices
    ensure_offers
    p @cur_prices
  end

  def suggest_action
    io = irrelevant_offer
    return io if io
    ss = sell_shares
    return ss if ss
    bs = buy_shares
    return bs if bs
    { type: "No Action" }
  end

  private

  def buy_shares
    max_difference = 0
    best_idx = nil
    @cur_prices["Buy Yes"].each_index do |idx|
      dif = @cur_prices["Buy Yes"][idx] - (100 - @cur_prices["Buy No"][idx])
      if dif > max_difference && !already_offers?(idx)
        max_difference = dif
        best_idx = idx
      end
    end
    puts yes_price_total
    puts no_price_total
    if max_difference > @purchase_above_difference
      if yes_price_total < no_price_total
        price = 100 - @cur_prices["Buy No"][best_idx] + price_difference
        price = 99 if price == 100
        @buy_offers[best_idx] = Offer.new(price, price, @cur_prices["Buy Yes"][best_idx])
        return {
          type: :buy,
          shares: :yes,
          idx: best_idx,
          price: price,
          quantity: 5
        }
      else
        price = 100 - @cur_prices["Buy Yes"][best_idx] + price_difference
        price = 99 if price == 100
        @buy_offers[best_idx] = Offer.new(price, price, @cur_prices["Buy No"][best_idx])
        return {
          type: :buy,
          shares: :no,
          idx: best_idx,
          price: price,
          quantity: 5
        }
      end
    end
    nil
  end

  def sell_shares
    result = nil
    result ||= sell_if_price_dropping
    result ||= sell_if_penny_difference
    result
  end

  def irrelevant_offer
    result = nil
    result ||= cancel_if_offer_beaten
    result ||= cancel_if_insufficient_difference
    result
  end

  def sell_if_price_dropping
    @cur_prices["Shares"].each_with_index do |quantity, idx|
      if quantity > 0
        if @cur_prices["Buy Yes"][idx] < @buy_offers[idx].max &&
          @cur_prices["Sell Offers"][idx] == 0
          price = @cur_prices["Buy Yes"][idx] - price_difference
          price = 1 if price == 0
          @sell_offers[idx] = Offer.new(price, 100 - @cur_prices["Buy No"][idx], price)
          return {
            type: :sell,
            shares: :yes,
            idx: idx,
            price: price,
            quantity: quantity
          }
        end
      elsif quantity < 0
        if @cur_prices["Buy No"][idx] < @buy_offers[idx].max &&
          @cur_prices["Sell Offers"][idx] == 0
          price = @cur_prices["Buy No"][idx] - price_difference
          price = 1 if price == 0
          @sell_offers[idx] = Offer.new(price, 100 - @cur_prices["Buy Yes"][idx], price)
          return {
            type: :sell,
            shares: :no,
            idx: idx,
            price: price,
            quantity: -quantity
          }
        end
      end
    end
    nil
  end

  def sell_if_penny_difference
    @cur_prices["Shares"].each_with_index do |quantity, idx|
      if quantity != 0
        if @cur_prices["Buy Yes"][idx] - (100 - @cur_prices["Buy No"][idx]) == 1
          price = quantity > 0 ?
            @cur_prices["Buy Yes"][idx] - price_difference :
            @cur_prices["Buy No"][idx] - price_difference
          return {
            type: :sell,
            shares: quantity > 0 ? :yes : :no,
            idx: idx,
            price: price,
            quantity: quantity.abs
          }
        end
      end
    end
    nil
  end

  def cancel_if_offer_beaten
    result = nil
    result ||= cancel_buy_if_beaten
    result ||= cancel_sell_if_beaten
    result
  end

  def cancel_buy_if_beaten
    @cur_prices["Buy Offers"].each_with_index do |quantity, idx|
      if quantity > 0
        if @buy_offers[idx].price < 100 - @cur_prices["Buy No"][idx] || @buy_offers[idx].price == 100
          return {
            type: :cancel,
            offer: :buy,
            idx: idx
          }
        end
      end
      if quantity < 0
        if @buy_offers[idx].price < 100 - @cur_prices["Buy Yes"][idx] || @buy_offers[idx].price == 100
          return {
            type: :cancel,
            offer: :buy,
            idx: idx
          }
        end
      end
    end
    nil
  end

  def cancel_sell_if_beaten
    @cur_prices["Sell Offers"].each_with_index do |quantity, idx|
      if quantity > 0
        if @sell_offers[idx].price > @cur_prices["Buy Yes"][idx]
          return {
            type: :cancel,
            offer: :sell,
            idx: idx
          }
        end
      end
      if quantity < 0
        p "Selling No Check"
        p @sell_offers[idx].price
        p @cur_prices["Buy No"][idx]
        if @sell_offers[idx].price > @cur_prices["Buy No"][idx]
          return {
            type: :cancel,
            offer: :sell,
            idx: idx
          }
        end
      end
    end
    nil
  end

  def cancel_if_insufficient_difference
    result = nil
    result ||= check_for_insufficient_difference("Buy Offers")
    result ||= check_for_insufficient_difference("Sell Offers")
    result
  end

  def check_for_insufficient_difference(type)
    @cur_prices[type].each_with_index do |quantity, idx|
      if quantity != 0
        if @cur_prices["Buy Yes"][idx] - (100 - @cur_prices["Buy No"][idx]) < @purchase_above_difference
          return {
            type: :cancel,
            offer: type == "Buy Offers" ? :buy : :sell,
            idx: idx
          }
        end
      end
    end
    nil
  end

  def already_offers?(idx)
    @cur_prices["Shares"][idx] != 0 ||
    @cur_prices["Buy Offers"][idx] != 0 ||
    @cur_prices["Sell Offers"][idx] != 0
  end

  def ensure_offers
    unless @cur_prices["Buy Yes"].empty?
      @buy_offers ||= Array.new(@cur_prices["Buy Yes"].length) { Offer.new(100, 100, 100) }
      @sell_offers ||= Array.new(@cur_prices["Buy Yes"].length) { Offer.new(100, 100, 100) }
    end
  end

  def yes_price_total
    @cur_prices["Buy Yes"].reduce(:+) - 100
  end

  def no_price_total
    total = 0
    @cur_prices["Buy No"].each do |val|
      total += val - 100
    end
    total + 100
  end

  def price_difference
    @match_other_bids ? 0 : 1
  end

  def update_cur_prices
    @cur_prices = Hash.new { [] }
    update_buy_prices
    update_latest
    update_holdings
  end

  def update_buy_prices
    elements = @driver.find_elements(css: '.text-center span[class*="sharesUp"]')
    elements.each_with_index do |el, idx|
      value = el.attribute("innerText").to_i
      value = 100 if value == 0
      if idx % 2 == 0
        @cur_prices["Buy Yes"] = @cur_prices["Buy Yes"].push(value)
      end
    end
    elements = @driver.find_elements(css: '.text-center span[class*="sharesDown"]')
    elements.each_with_index do |el, idx|
      value = el.attribute("innerText").to_i
      value = 100 if value == 0
      if idx % 2 == 0
        @cur_prices["Buy No"] = @cur_prices["Buy No"].push(value)
      end
    end
  end

  def update_latest
    elements = @driver.find_elements(css: '.text-center b:not(.label)')
    elements.each do |el|
      @cur_prices["Latest"] = @cur_prices["Latest"].push(el.attribute("innerText").to_i)
    end
  end

  def update_holdings
    elements = @driver.find_elements(css: '.text-center b.label')
    elements.each_with_index do |el, idx|
      if idx % 3 == 0
        @cur_prices["Shares"] = @cur_prices["Shares"].push(el.attribute("innerText").to_i)
        @cur_prices["Shares"][-1] *= -1 if el.attribute("outerHTML").include?("alert-danger")
      elsif idx % 3 == 1
        @cur_prices["Buy Offers"] = @cur_prices["Buy Offers"].push(el.attribute("innerText").to_i)
        @cur_prices["Buy Offers"][-1] *= -1 if el.attribute("outerHTML").include?("alert-danger")
      else
        @cur_prices["Sell Offers"] = @cur_prices["Sell Offers"].push(el.attribute("innerText").to_i)
        @cur_prices["Sell Offers"][-1] *= -1 if el.attribute("outerHTML").include?("alert-offers-red")
      end
    end
  end

end
