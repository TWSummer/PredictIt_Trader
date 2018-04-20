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
      sleep(2)
    end
  end

  private

  def perform_action(action)
    buy(action) if action[0] == "buy"

  end

  def buy(action)
    index = action[2] * 2
    index += 1 if action[1] = "no"
    element = @driver.find_elements(css: '.text-center span a[class*="showPointer"]')[0]
    p element
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
