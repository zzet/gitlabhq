# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :banner do
    title
    description
    category :info
    start_date "2013-10-02 11:24:29"
    end_date "2013-10-02 11:24:29"
    author
    entity_id nil
    entity_type nil
  end
end
