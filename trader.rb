require "selenium-webdriver"
require "./credentials"

class Trader
  def initialize
    @driver = Selenium::WebDriver.for :firefox
  end

  def run
    login
    navigate_to_market
    collect_prices
  end

  private

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

  def collect_prices
    elements = @driver.find_elements(css: '.text-center span a[class*="showPointer"]')
    elements.each do |el|
      p el.attribute("innerText")
    end
  end

  def navigate_to_market
    @driver.navigate.to "https://www.predictit.org/Market/4314/What-will-Trump's-538-job-approval-index-be-for-April-23"
  end
end

trader = Trader.new
trader.run

# driver = Selenium::WebDriver.for :firefox
# driver.navigate.to "https://www.predictit.org/"
#
# element = driver.find_elements(css: 'a[href="#SignInModal"]')[0]
# p element
# element.click
# element = driver.find_element(id: 'Email')
# element.send_keys "TWSummer@gmail.com"
# element = driver.find_element(id: 'Password')
# element.send_keys "Kitkat#0"
# element.submit
# sleep(2)
# driver.navigate.to "https://www.predictit.org/Market/4314/What-will-Trump's-538-job-approval-index-be-for-April-23"
# elements = driver.find_elements(css: 'a[class*="showPointer"]')
# elements.each do |el|
#   p el.attribute("innerText")
# end
#
# puts driver.title

# driver.quit
