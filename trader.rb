require "selenium-webdriver"
require "./credentials"
require "./market_values"

class Trader
  def initialize
    @driver = Selenium::WebDriver.for :firefox
    @market_values = MarketValues.new(@driver)
    @market_url = "https://www.predictit.org/Market/4345/What-will-Democrats'-538-Congressional-polling-edge-be-for-May-2"
  end

  def run
    login
    navigate_to_market
    update_prices
    while true
      # begin
        navigate_to_market
        update_prices
        action = @market_values.suggest_action
        p action
        perform_action(action)
        sleep(4)
      # rescue
      # end
    end
  end

  private

  def perform_action(action)
    buy(action) if action[:type] == :buy
    cancel(action) if action[:type] == :cancel
    sell(action) if action[:type] == :sell
  end

  def buy(action)
    col = action[:shares] == :yes ? 3 : 5
    element = @driver.find_elements(css: "tbody tr:nth-of-type(#{action[:idx] + 1}) td:nth-of-type(#{col}) span a")[0]
    element.click
    sleep(2)
    element = @driver.find_element(id: 'Quantity')
    3.times { element.send_keys "\ue003" }
    element.send_keys action[:quantity]
    element = @driver.find_element(id: 'PricePerShare')
    3.times { element.send_keys "\ue017" }
    element.send_keys action[:price]
    button_id = action[:shares] == :no ? "submitSell" : "submitBuy"
    element = @driver.find_element(id: button_id)
    element.click
    sleep(1)
    element = @driver.find_elements(css: 'button.btn-success')[0]
    element.click
  end

  def sell(action)
    col = action[:shares] == :yes ? 4 : 6
    element = @driver.find_elements(css: "tbody tr:nth-of-type(#{action[:idx] + 1}) td:nth-of-type(#{col}) span a")[0]
    element.click
    sleep(1)
    complete_purchase(action)
  end

  def complete_purchase(action)
    element = @driver.find_element(id: 'Quantity')
    3.times { element.send_keys "\ue003" }
    element.send_keys action[:quantity]
    element = @driver.find_element(id: 'PricePerShare')
    3.times { element.send_keys "\ue017" }
    element.send_keys action[:price]
    button_id = action[:shares] == :no || action[:type] == :sell ? "submitSell" : "submitBuy"
    element = @driver.find_element(id: button_id)
    element.click
    sleep(1)
    element = @driver.find_elements(css: 'button.btn-success')[0]
    element.click
  end

  def cancel(action)
    col = action[:offer] == :buy ? 8 : 9
    element = @driver.find_elements(css: "tbody tr:nth-of-type(#{action[:idx] + 1}) td:nth-of-type(#{col}) a")[0]
    element.click
    sleep(3)
    element = @driver.find_elements(css: "#ownershipmodal a.cancelOrderBook")[0]
    element.click
    sleep(1)
    @driver.switch_to.alert.accept
  end

  def login
    @driver.navigate.to "https://www.predictit.org/"
    element = @driver.find_elements(css: 'a[href="#SignInModal"]')[0]
    element.click
    element = @driver.find_element(id: 'Email')
    element.send_keys Credentials.username
    element = @driver.find_element(id: 'Password')
    element.send_keys Credentials.password
    element.submit
    sleep(2)
  end

  def navigate_to_market
    @driver.navigate.to @market_url
    expand
  end

  def update_prices
    @market_values.update_prices
    while @market_values.cur_prices == {}
      sleep(1)
      @market_values.update_prices
    end
  end

  def expand
    sleep(1)
    begin
      element = @driver.find_element(id: "showMoreLinkContent")
      element.click if element
    rescue
    end
  end
end

trader = Trader.new
trader.run
