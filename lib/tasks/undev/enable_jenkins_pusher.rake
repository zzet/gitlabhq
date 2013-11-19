namespace :undev do
  desc "Undev | Enable Jenkins pusher in current services"
  task enable_jenkins_pusher: :environment do
    Service::Jenkins.find_each do |service|
      cfg = Service::Configuration::Jenkins.new
      cfg.service = service
      cfg.save
    end

    ci_pattern = Service.find(284)

    if ci_pattern.respond_to?(:configuration)

      configuration = ci_pattern.configuration

      configuration.host = "http://ci01.undev.cc"
      configuration.push_path = "/push/build"
      configuration.merge_request_path = "/merge-request/build"
      configuration.branches = "master, develop, staging"
      configuration.merge_request_enabled = true
      configuration.save

      ci_pattern.children.each do |ci|
        attrs = ci_pattern.configuration.attributes

        %w(id service_id service_type created_at updated_at).each do |key|
          attrs.delete(key)
        end

        ci.configuration.update_attributes(attrs)
      end
    end
  end
end
