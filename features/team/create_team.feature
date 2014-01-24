Feature: Team Pages
  Background:
    Given I sign in as a user

  Scenario: Open team index page
    When I visit team index page
    Then I should be redirected to dashbord team page

  Scenario: Create a team from dasboard
    Given I have group with projects
    And I visit dashboard page
    When I click new team link
    And submit form with new team info
    Then I should be redirected to team page
    And I should see newly created team
