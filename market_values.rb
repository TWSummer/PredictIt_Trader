require "./offer"

class MarketValues
  PURCHASE_ABOVE_DIFFERENCE = 5

  def initialize(driver)
    @driver = driver
  end

  def update_prices
    @prev_prices = @cur_prices
    update_cur_prices
    @offers ||= Array.new(@cur_prices.length) { Offer.new(0, 0, 0) }
    p @cur_prices
    p @prev_prices
  end

  def suggest_action
    return irrelevant_offer if irrelevant_offer
    return sell_shares if sell_shares
    return buy_shares if buy_shares
    ["No Action"]
  end

  private

  def buy_shares
    max_difference = 0
    best_idx = nil
    @cur_prices["Buy Yes"].each_index do |idx|
      dif = @cur_prices["Buy Yes"][idx] - (100 - @cur_prices["Buy No"][idx])
      if dif > max_difference
        max_difference = dif
        best_idx = idx
      end
    end
    puts yes_price_total
    puts no_price_total
    if max_difference > PURCHASE_ABOVE_DIFFERENCE
      if yes_price_total < no_price_total
        return ["buy", "yes", best_idx]
      else
        return ["buy", "no", best_idx]
      end
    end
    nil
  end

  def sell_shares
    nil
  end

  def irrelevant_offer
    @cur_prices["Buy Offers"].each_with_index do |quantity, idx|
      if quantity > 0
        if @offers[idx].price < 100 - @cur_prices["Buy Yes"][idx]
          return ["cancel", "buy", idx]
        end
      end
    end
    @cur_prices["Sell Offers"].each_with_index do |quantity, idx|
      if quantity > 0
        if @offers[idx].price > 100 - @cur_prices["Buy No"][idx]
          return ["cancel", "sell", idx]
        end
      end
    end
    nil
  end

  def yes_price_total
    @cur_prices["Buy Yes"].reduce(:+)
  end

  def no_price_total
    @cur_prices["Buy No"].reduce { |tot, el| tot + 100 - el }
  end

  def update_cur_prices
    @cur_prices = Hash.new { [] }
    update_buy_prices
    update_latest
    update_holdings
  end

  def update_buy_prices
    elements = @driver.find_elements(css: '.text-center span a[class*="showPointer"]')
    elements.each_with_index do |el, idx|
      if idx % 2 == 0
        @cur_prices["Buy Yes"] = @cur_prices["Buy Yes"].push(el.attribute("innerText").to_i)
      else
        value = el.attribute("innerText").to_i
        value = 100 if value == 0
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
      elsif idx % 3 == 1
        @cur_prices["Buy Offers"] = @cur_prices["Buy Offers"].push(el.attribute("innerText").to_i)
      else
        @cur_prices["Sell Offers"] = @cur_prices["Sell Offers"].push(el.attribute("innerText").to_i)
      end
    end
  end

end
