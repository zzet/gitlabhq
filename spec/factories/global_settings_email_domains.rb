# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :global_settings_email_domain, :class => 'GlobalSettings::EmailDomains' do
    domain "test_domain.com"
    description "domain description"
  end
end
