class Legacy::Site < LegacyDb
  has_many :projects

  HTTP_CLONING_SUBDOMAIN = 'git'

  def self.default
    new(:title => "Gitorious", :subdomain => nil)
  end
end
