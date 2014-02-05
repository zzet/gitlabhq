Feature: Project ci build
  Background:
    Given I sign in as a user
    And I own a project
    Given Project has Jenkins Ci service
    Given Ci build
    Given I visit my project's commits page

  @javascript
  Scenario: On Project Commits
    Given I click on more info
    Then I see additional parameters
    Then I rebuild
