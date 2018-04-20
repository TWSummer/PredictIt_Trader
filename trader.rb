require "selenium-webdriver"
require "./credentials"
require "./market_values"

class Trader
  def initialize
    @driver = Selenium::WebDriver.for :firefox
    @market_values = MarketValues.new(@driver)
  end

  def run
    login
    navigate_to_market
    @market_values.update_prices
    while true
      navigate_to_market
      @market_values.update_prices
      action = @market_values.suggest_action
      p action
      perform_action(action)
      sleep(5)
    end
  end

  private

  def perform_action(action)
    buy(action) if action[:type] == :buy
    cancel(action) if action[:type] == :cancel

  end

  def buy(action)
    col = action[:shares] == :yes ? 3 : 5
    element = @driver.find_elements(css: "tbody tr:nth-of-type(#{action[:idx] + 1}) td:nth-of-type(#{col}) span a")[0]
    element.click
    sleep(1)
    element = @driver.find_element(id: 'Quantity')
    3.times { element.send_keys "\ue003" }
    element.send_keys action[:quantity]
    element = @driver.find_element(id: 'PricePerShare')
    3.times { element.send_keys "\ue017" }
    element.send_keys action[:price]
    button_id = action[:shares] == :no ? "submitSell" : "submitBuy"
    element = @driver.find_element(id: button_id)
    element.click
    sleep(100)
    element = @driver.find_elements(css: 'button.btn-success')[0]
    element.click
  end

  def cancel(action)
    col = action[:offer] == :buy ? 8 : 9
    element = @driver.find_elements(css: "tbody tr:nth-of-type(#{action[:idx] + 1}) td:nth-of-type(#{col}) a")[0]
    element.click
    sleep(1)
    element = @driver.find_elements(css: "a.cancelOrderBook")[0]
    element.click
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
    @driver.navigate.to "https://www.predictit.org/Market/4314/What-will-Trump's-538-job-approval-index-be-for-April-23"
  end
end

trader = Trader.new
trader.run
