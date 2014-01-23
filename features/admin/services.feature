Feature: Admin Services
  Background:
    Given I sign in as an admin
    And I have service pattern
    And I visit admin services page

  Scenario: See service pattern list
    Then I should be all services patterns

  Scenario: Create a service pattern
    When I click new service pattern link
    And submit form with new service pattern info
    Then I should be redirected to admin service page
    And I should see newly created service pattern
