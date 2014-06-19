class ProfileEmails < Spinach::FeatureSteps
  include SharedAuthentication

  Then 'I visit profile emails page' do
    visit profile_emails_path
  end

  Then 'I should see my emails' do
    page.should have_content(@user.email)
    @user.emails.each do |email|
      page.should have_content(email.email)
    end
  end

  And 'I submit new email "my@email.com"' do
    fill_in "email_email", with: "my"
    click_button "Add"
  end

  Then 'I should see new email "my@email.com"' do
    email = @user.emails.find_by(email: "my@#{Gitlab.config.corporate_email_domains.first}")
    email.should_not be_nil
    page.should have_content("my@#{Gitlab.config.corporate_email_domains.first}")
  end

  Then 'I should not see email "my@email.com"' do
    email = @user.emails.find_by(email: "my@#{Gitlab.config.corporate_email_domains.first}")
    email.should be_nil
    page.should_not have_content("my@#{Gitlab.config.corporate_email_domains.first}")
  end

  Then 'I click link "Remove" for "my@email.com"' do
    # there should only be one remove button at this time
    click_link "Remove"
    # force these to reload as they have been cached
    @user.emails.reload
  end

  And 'I submit duplicate email @user.email' do
    fill_in "email_email", with: @user.email.split("@").first
    click_button "Add"
  end

  Then 'I should not have @user.email added' do
    email = @user.emails.find_by(email: @user.email)
    email.should be_nil
  end
end
