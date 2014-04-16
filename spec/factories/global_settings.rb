# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :global_setting, :class => 'GlobalSettings' do
    allowed_email_domains "MyText"
  end
end
