require 'selenium-webdriver'
require "rspec"
require "rmagick"
require 'pathname'
require 'fileutils'
require './support/env.rb'
include Magick
include RSpec::Expectations

### GIVEN definitions ###


Given ("We navigate to NCS homepage") do
  #sleep 5 ### Timeout for preventing DDoS etc.
  $driver.navigate.to "http://localhost/"
  expect($driver.current_url).to eq("http://localhost/")
end

Given (/^We navigate to NCS homepage and login as admin$/) do
  steps %(
    Given We navigate to NCS homepage
    When We click on the button ANMELDEN
    And Enter the Benutzername "admin" with the related Passwort "!NCS2019"
    Then The login is successful and the Dashboard will be shown
  )
end

Given (/^We click on the button Benutzer$/) do
  $driver.find_element(xpath: "//*[@class = 'wp-menu-image dashicons-before dashicons-admin-users']" ).click
  begin
    element = $wait5.until { $driver.find_element(:class => "wp-heading-inline") }
    expect(element.text).to include('Benutzer')
  end
end

### AND definitions ###

And (/^Enter the Benutzername "(.*?)" with the related Passwort "(.*?)"$/) do |username,userpwd|
  $driver.find_element(:id, "user_login").click
  $driver.find_element(:id, "user_login").send_keys (username)
  $driver.find_element(:id, "user_pass").click
  $driver.find_element(:id, "user_pass").send_keys (userpwd)
end

And (/^Enter an existing Benutzername "(.*?)" with a wrong Passwort "(.*?)"$/) do |username,userpwd|
  $username = username
  $driver.find_element(:id, "user_login").click
  $driver.find_element(:id, "user_login").send_keys ($username)
  $driver.find_element(:id, "user_pass").click
  $driver.find_element(:id, "user_pass").send_keys (userpwd)
end

And (/^Enter an unknown Benutzername "(.*?)" with a correct Passwort "(.*?)"$/) do |username,userpwd|
  $driver.find_element(:id, "user_login").click
  $driver.find_element(:id, "user_login").send_keys (username)
  $driver.find_element(:id, "user_pass").click
  $driver.find_element(:id, "user_pass").send_keys (userpwd)
end

And (/^User enters Benutzername "(.*?)" and Passwort "(.*?)"$/) do |arg1, arg2|
  $driver.find_element(:id, "user_login").click
  $driver.find_element(:id, "user_login").send_keys (arg1)
  $driver.find_element(:id, "user_pass").click
  $driver.find_element(:id, "user_pass").send_keys (arg2)
end

And (/^The user will be logged out successful at the end$/) do
  $driver.action.move_to($driver.find_element(:id => "wp-admin-bar-my-account")).perform

  logoutbutton = $wait5.until { $driver.find_element(:link, "Abmelden") }
  logoutbutton.click

  element = $wait5.until { $driver.find_element(:class => "message") }
  expect(element.text).to include('Du hast dich erfolgreich abgemeldet.')
end

### WHEN definitions ###

When (/^We click on the button ANMELDEN$/) do
  $driver.find_element(:link, "Anmelden").click
  element = $wait5.until { $driver.find_element(:id => "login") }
end

When (/^We enter the all required information for the new user$/) do |table|
  $successarray = ""
  failurearray = ""
  error = false

  data = table.hashes.each do |userinfo|

    $driver.action.move_to($driver.find_element(:xpath, "//*[@class = 'wp-menu-image dashicons-before dashicons-admin-users']" )).perform

    element = $wait5.until { $driver.find_element(:link, "Neu hinzufügen") }
    element.click
    $driver.find_element(:id, "user_login").click
    $driver.find_element(:id, "user_login").send_keys userinfo["Benutzername"]
    $driver.find_element(:id, "email").click
    $driver.find_element(:id, "email").send_keys userinfo["EMail"]
    $driver.find_element(:id, "first_name").click
    $driver.find_element(:id, "first_name").send_keys userinfo["Vorname"]
    $driver.find_element(:id, "last_name").click
    $driver.find_element(:id, "last_name").send_keys userinfo["Nachname"]
    $driver.find_element(:xpath, "(//button[@type='button'])[3]").click
    $driver.find_element(:id, "pass1-text").click
    $driver.find_element(:id, "pass1-text").clear

    userinfo["Passwort"] =~ /^(.)(.*)/; fcpw = $1; rcpw =$2;
    $driver.find_element(:id, "pass1-text").send_keys (fcpw)
    $driver.find_element(:id, "pass1-text").send_keys (rcpw)

    $driver.find_element(:id, "send_user_notification").click

    begin
      Selenium::WebDriver::Support::Select.new($driver.find_element(:id, "role")).select_by(:text, (userinfo["Rolle"]))
    rescue StandardError => e
      failurearray = failurearray + e.message + " -> Error during creation of user \"" + userinfo["Benutzername"] + "\"\n"
      error = true
      encoded_img = $driver.screenshot_as(:base64)
      embed("data:image/png;base64,#{encoded_img}",'image/png')
      next
    end

    $driver.find_element(:id, "role").click

    encoded_img = $driver.screenshot_as(:base64)
    embed("data:image/png;base64,#{encoded_img}",'image/png')

    $driver.find_element(:id, "createusersub").click

    begin
      element = $wait2.until { $driver.find_element(:id => "message") }
      expect(element.text).to start_with('Neuer Benutzer erstellt.')
    rescue StandardError => e
      failurearray = failurearray + e.message + " -> Error during creation of user " + userinfo["Benutzername"] + "\n"
      error = true
      encoded_img = $driver.screenshot_as(:base64)
      embed("data:image/png;base64,#{encoded_img}",'image/png')
      next
    end

    encoded_img = $driver.screenshot_as(:base64)
    embed("data:image/png;base64,#{encoded_img}",'image/png')

    $successarray = $successarray + "Creation of user \"" +userinfo["Benutzername"]+ "\" was successfull\n"

  end

  if error == true
    puts $successarray
    fail failurearray + "Failure in execution. Please check above messages for details."
  end

end

When (/^we click on Löschen for the following user$/)do |table|
  $successarray = ""
  $failurearray = ""
  $error = false

  table.raw.each do |user|
    user.each do |user2|

      loop do
        $usernok = false
        begin
          $driver.find_element(:link => user2).attribute("href") =~ /user_id=(\d*)/
          $userid = $1

          $driver.action.move_to($driver.find_element(:link => user2)).perform
          break
        rescue StandardError => e
          if ( e.message =~ /Unable to locate element:/ && $driver.find_elements(:class, "next-page").empty? == false )
            $driver.find_element(:class, "next-page").click
          elsif ( e.message =~ /is out of bounds of viewport/ )
            element2 = $driver.find_element(:link => user2)
            $driver.execute_script("arguments[0].scrollIntoView(false);", element2)
            $driver.action.move_to($driver.find_element(:link => user2)).perform
            break
          else
            $failurearray = $failurearray + e.message + " -> Error during deletion of user \"" +user2+ "\"\n"
            $error = true
            $usernok = true
            encoded_img = $driver.screenshot_as(:base64)
            embed("data:image/png;base64,#{encoded_img}",'image/png')
            break
          end
        end
      end

      if $usernok == true
        next
      end

      element = $wait5.until { $driver.find_element(:xpath, "//a[contains(@href, 'users.php?action=delete&user="+$userid+"')]") }
      element.click

      begin
        element = $wait5.until { $driver.find_element(:class => "wrap") }
        expect(element.text).to start_with('Benutzer löschen')
      end

      if ( $driver.find_elements(:id, "delete_option0").empty? == false )
        $driver.find_element(:id, "delete_option0").click
      end

      $driver.find_element(:id, "submit").click

      begin
        element = $wait5.until { $driver.find_element(:id => "message") }
        expect(element.text).to start_with('Benutzer gelöscht')
      end

      $successarray = $successarray + "Deletion of user \"" +user2+ "\" was successfull\n"
    end
  end

  if $error == true
    puts $successarray
    fail $failurearray + "Failure in execution. Please check above messages for details."
  end

end

### THEN definitions ###

Then (/^The login is successful and the Dashboard will be shown$/) do
  $driver.find_element(:id, "loginform").submit
  element = $wait5.until { $driver.find_element(:id, "wp-admin-bar-my-account") }
  expect(element.text).to start_with('Willkommen')
end

Then (/^An error message will shown that the password for the user is incorrect$/) do
  $driver.find_element(:id, "loginform").submit
  element = $wait5.until { $driver.find_element(:id => "login_error") }
  expect(element.text).to start_with('FEHLER: Das Passwort, das du für den Benutzernamen ' +$username+ ' eingegeben hast, ist nicht korrekt.')
end

Then (/^An error message will shown that the user is not known in the system$/) do
  $driver.find_element(:id, "loginform").submit
  element = $wait5.until { $driver.find_element(:id => "login_error") }
  expect(element.text).to start_with('FEHLER: Ungültiger Benutzername.')
end

Then (/^Creation of all users are ok$/) do
  puts $successarray
end

Then (/^Deletion is ok$/) do
  puts $successarray
end
