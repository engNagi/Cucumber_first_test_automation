require "selenium-webdriver"
require "rspec"
require "rmagick"
require 'pathname'
require 'fileutils'
include Magick
include RSpec::Expectations

puts "!!! Enviroment has been loaded !!!"

############

def getDriver
  if ENV['BROWSER'] != nil
    if ENV['BROWSER'] == "firefox"
      if ENV['OPTION'] == "headless"
        $options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
        return Selenium::WebDriver.for(:firefox, options: $options)
      else
        return Selenium::WebDriver.for :firefox
      end
    elsif ENV['BROWSER'] == "chrome"
      if ENV['OPTION'] == "headless"
        $options = Selenium::WebDriver::Chrome::Options.new(args: ['-headless'])
        return Selenium::WebDriver.for(:chrome, options: $options)
      else
        return Selenium::WebDriver.for :chrome
      end
    elsif ENV['BROWSER'] != "chrome" || ENV['BROWSER'] != "firefox"
      raise Exception.new("Unsupported browser: " + ENV['BROWSER'] )
    end
  else
    #$options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
    #return Selenium::WebDriver.for(:firefox, options: $options)

    return Selenium::WebDriver.for :firefox
  end
end

driver = getDriver

accept_next_alert = true
### Setting implicit waits from 30 seconds to a user defined time.
### This will avoid long waiting time if e.g. some elements will be not found.
driver.manage.timeouts.implicit_wait = 10
driver.manage.timeouts.script_timeout = 30
verification_errors = []

### Creation of directory for HTML reporting ###

if ARGV.include? "html"
  ARGV.each do |value|
    if value =~ /(.*)\.html/
      $newdir = "#{Time.now.strftime($1)}"
      $pic = $1
      break
    end
  end

  destination = "reporting/" +$newdir
  Dir.mkdir(destination) unless File.exists?(destination)
  pic = $pic
end

### Global BEFORE definitions ###

Before do|scenario|

  # Scenario name
  $scenario_name = scenario.name.gsub(/\s|#/, '_')

  $driver = driver
  $destination = destination
  $picname = pic

  #### set window size using Dimension struct
  target_size = Selenium::WebDriver::Dimension.new(1280, 800)
  $driver.manage.window.size = target_size
  #puts $driver.manage.window.size

  ### maximize window
  #$driver.manage.window.maximize
  #puts $driver.manage.window.size

  $wait2 = Selenium::WebDriver::Wait.new(:timeout => 2) # seconds
  $wait5 = Selenium::WebDriver::Wait.new(:timeout => 5) # seconds
  $wait10 = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
end

### Global AFTER_STEP definitions ###

AfterStep do |scenario|
  if ARGV.include? "html"
    #encoded_img = $driver.screenshot_as(:base64)
    #embed("data:image/png;base64,#{encoded_img}",'image/png')

    picture = $destination + "/#{Time.now.strftime($picname + "-Scenario_" + $scenario_name + "-time_%H%M%S")}.png"
    picture2 = $destination + "/#{Time.now.strftime($picname + "-Scenario_" + $scenario_name + "-time_%H%M%S")}.jpg"
    $driver.save_screenshot picture

    image = Image.read(picture).first
    image.write(picture2)
    embed(picture2,'image/jpg')

    #File.delete(picture) if File.exist?(picture)
    sleep 1
  end
end

### Global AFTER definitions ###

After ('@LoginAdmin or @AddUserList or @DeleteUserList') do |scenario|
  if  scenario.status =~ /^passed$/
    $driver.action.move_to($driver.find_element(:id => "wp-admin-bar-my-account")).perform
    element = $wait5.until { $driver.find_element(:link, "Abmelden") }
    element.click

    begin
      element = $wait5.until { $driver.find_element(:class => "message") }
      expect(element.text).to include('Du hast dich erfolgreich abgemeldet.')
    end

  end
end

at_exit do
  if (defined?(options))
    driver.close
  end
end