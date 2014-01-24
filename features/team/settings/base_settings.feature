Feature: Team settings pages
  Background:
    Given I sign in as a user
    Given I have team
    And I visit team page
    And I visit team settings page

  Scenario: Edit base team settings
    When I submit form with updated team info
    Then I should be redirected to team settings page
    And I should see updated team

  Scenario: Delete team
    When I open Danger settings
    And click on Remove Button
    Then I should be redirected on Dashboard page
    And team shoud be deleted
