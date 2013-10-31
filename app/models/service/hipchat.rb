# == Schema Information
#
# Table name: services
#
#  id                 :integer          not null, primary key
#  type               :string(255)
#  title              :string(255)
#  project_id         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  state              :string(255)
#  service_pattern_id :integer
#  public_state       :string(255)
#  active_state       :string(255)
#  description        :text
#

class Service::Hipchat < Service
  default_title       'Hipchat'
  default_description 'Simple web-based real-time group chat'
  service_name        'hipchat'

  has_one :configuration, as: :service, class_name: Service::Configuration::Hipchat

  delegate :room, :token, to: :configuration, prefix: false

  def execute(push_data)
    gate[room].send('Gitlab', create_message(push_data))
  end

  private

  def gate
    @gate ||= HipChat::Client.new(token)
  end

  def create_message(push)
    ref = push[:ref].gsub("refs/heads/", "")
    before = push[:before]
    after = push[:after]

    message = ""
    message << "#{push[:user_name]} "
    if before =~ /000000/
      message << "pushed new branch <a href=\"#{project.web_url}/commits/#{ref}\">#{ref}</a> to <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/,'')}</a>\n"
    elsif after =~ /000000/
      message << "removed branch #{ref} from <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/,'')}</a> \n"
    else
      message << "#pushed to branch <a href=\"#{project.web_url}/commits/#{ref}\">#{ref}</a> "
      message << "of <a href=\"#{project.web_url}\">#{project.name_with_namespace.gsub!(/\s/,'')}</a> "
      message << "(<a href=\"#{project.web_url}/compare/#{before}...#{after}\">Compare changes</a>)"
      for commit in push[:commits] do
        message << "<br /> - #{commit[:message]} (<a href=\"#{commit[:url]}\">#{commit[:id][0..5]}</a>)"
      end
    end

    message
  end
end
