Feature: Verification of user login and management of the website

  Background:
    Given We navigate to NCS homepage

  @LoginAdmin @LoginSmoke @Regression
  Scenario: Login of Admin
    When We click on the button ANMELDEN
    And Enter the Benutzername "admin" with the related Passwort "!NCS2019"
    Then The login is successful and the Dashboard will be shown

  @LoginWrongPW @LoginFailed @LoginSmoke @Regression
  Scenario: Login with wrong Password
    When We click on the button ANMELDEN
    And Enter an existing Benutzername "admin" with a wrong Passwort "nopassword"
    Then An error message will shown that the password for the user is incorrect

  @LoginWrongUser @LoginFailed @LoginSmoke @Regression
  Scenario: Login with wrong User
    When We click on the button ANMELDEN
    And Enter an unknown Benutzername "dieter" with a correct Passwort "!NCS2019"
    Then An error message will shown that the user is not known in the system

  @AddUserList @Regression
  Scenario: Create a new users with different Rolle
    Given We navigate to NCS homepage and login as admin
    When We enter the all required information for the new user
      | Benutzername      | EMail                     		| Vorname | Nachname | Passwort 				 | Rolle    		|
      | Mitarbeiter-Klaus | klaus@hatgarkeinemail.org 		| Klaus   | Platt    | mitarbeiter-klaus | Mitarbeiter 	|
      | Redakteur-Wilhelm	| wilhelm@hatgarkeinemail.org 	| Wilhelm	| Tief     | redakteur-wilhelm | Redakteur		|
      | Autor-Joerg       | joerg@hatgarkeinemail.org 		| Jörg    | Hoch     | autor-joerg 			 | Autor    		|
      | Abonnent-Ludwig		| ludwig@hatgarkeinemail.org    | Ludwig  | Weit		 | abonnent-ludwig 	 | Abonnent			|
    Then Creation of all users are ok

  @LoginListOfUser @Regression
  Scenario Outline: Login with different users on the website
    When We click on the button ANMELDEN
    And User enters Benutzername "<username>" and Passwort "<password>"
    Then The login is successful and the Dashboard will be shown
    And The user will be logged out successful at the end

    Examples:
      | username          | password          |
      | admin             | !NCS2019          |
      | Mitarbeiter-Klaus | mitarbeiter-klaus |
      | Redakteur-Wilhelm	| redakteur-wilhelm |
      | Autor-Joerg       | autor-joerg 			|
      | Abonnent-Ludwig		| abonnent-ludwig 	|

  @DeleteUserList @Regression
  Scenario: Deletion of user in looping
    Given We navigate to NCS homepage and login as admin
    Given We click on the button Benutzer
    When we click on Löschen for the following user
      | Mitarbeiter-Klaus | Redakteur-Wilhelm | Autor-Joerg | Abonnent-Ludwig |
    Then Deletion is ok
