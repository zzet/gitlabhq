class LegacyDb < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "legacy_production"
end

class NewDb < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "production"
end
