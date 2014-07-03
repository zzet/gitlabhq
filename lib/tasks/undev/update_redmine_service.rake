namespace :undev do
  namespace :services do
    desc "update redmine service"
    task update_redmine_service: :environment do
      p "Update service pattern"
      p "Add configuration"

      redmine_services = ::Service::Redmine.all
      redmine_services.find_each do |redmine_service|
        p "Redmine Service #{redmine_service.id} start"
        redmine_service.build_configuration
        redmine_service.save

        service_configuration = redmine_service.configuration

        service_configuration.domain = 'http://pm.undev.cc'
        service_configuration.web_hook_path = '/gitlab_hooks'
        service_configuration.save
        p "Redmine Service #{redmine_service.id} finish"
      end
      p 'Done'
    end
  end
end
