class MarketValues
  def initialize(driver)
    @driver = driver
  end

  def update_prices
    @prev_prices = @cur_prices
    update_cur_prices
    p @cur_prices
    p @prev_prices
  end

  private

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
        @cur_prices["Buy No"] = @cur_prices["Buy No"].push(el.attribute("innerText").to_i)
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
