Feature: Team settings pages
  Background:
    Given I sign in as a user
    Given I have team
    And I visit team page
    And I visit team settings page
    And I have user 'Sam'
    And I have user 'John'

  @javascript
  Scenario: Add and update and remove member to team
    When I visit members team settings page
    And I select user 'Sam' with role 'Master'
    Then I should be redirected to team members settings page
    And I should see 'Sam' in team members list with role 'Master'
    Then I update user 'Sam' to with 'Develop' role
    And I should be redirected to team members settings page
    And I should see 'Sam' in team members list with role 'Develop'
    Then I shoud remove user 'Sam' from team
    And I should be redirected to team members settings page
    And I should not see 'Sam' in team members list

  @javascript
  Scenario: Mass action with member and team
    When I visit members team settings page
    And I select users 'Sam' and 'John' with role 'Master'
    Then I should be redirected to team members settings page
    And I should see 'Sam' and 'John' in team members list with role 'Master'
