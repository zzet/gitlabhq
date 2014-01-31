Feature: Team settings pages
  Background:
    Given I sign in as a user
    Given I have team
    And I visit team page
    And I visit team settings page
    And I have project 'Undev'
    And I have project 'Gitlab'

  @javascript
  Scenario: Assign and resign project to team
    When I visit projects team settings page
    And I select project 'Undev'
    Then I should be redirected to team projects settings page
    And I should see 'Undev' in team projects list
    Then I shoud remove project 'Undev' from team
    And I should be redirected to team projects settings page
    And I should not see 'Undev' in team projects list

  #@javascript
  #Scenario: Mass add projects to team
    #When I visit projects team settings page
    #And I select projects 'Undev' and 'Gitlab'
    #Then I should be redirected to team projects settings page
    #And I should see 'Undev' and 'Gitlab' in team projects list
