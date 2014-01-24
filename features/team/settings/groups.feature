Feature: Team settings pages
  Background:
    Given I sign in as a user
    Given I have team
    And I visit team page
    And I visit team settings page
    And I have group 'Undev'
    And I have group 'Gitlab'

  @javascript
  Scenario: Assign and resign group to team
    When I visit groups team settings page
    And I select group 'Undev'
    Then I should be redirected to team groups settings page
    And I should see 'Undev' in team groups list
    Then I shoud remove group 'Undev' from team
    And I should be redirected to team groups settings page
    And I should not see 'Undev' in team groups list

  #@javascript
  #Scenario: Mass add groups to team
    #When I visit groups team settings page
    #And I select groups 'Undev' and 'Gitlab'
    #Then I should be redirected to team groups settings page
    #And I should see 'Undev' and 'Gitlab' in team groups list
