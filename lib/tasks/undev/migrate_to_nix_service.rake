namespace :undev do
  desc "Undev | migrate exist projects to nix service"
  task migrate_to_nix: :environment do

    ActiveRecord::Base.observers.disable(:all)

    nix_production_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6W7VnlqKXRv6J1et6iiqVJ7FfdHuGpSmDjnF5EQJwjkzQVwN/x+/J9qnPQQHR9xfJTqg7moxN0NwfmD2xnYz0c59OVJEDsMRdbl7QuodJ8jiZVXDv8M+Em6+iX1268BNT76CFC0V70DS5dro/kSXr/uHM7HR9qI1Uxh1oRELNhYT7F81IOWYwDYUfZiCjNnaLSsftd6HD9OIRa80RD4ZJbd3MmcMMrG3jyqqmshxKXTpkhumlOPRnqg12wiqGNjZjQh3x/VYzOtii2SJ/10pYep0CHvZEJ8kD9VVPumQEotZmJPRw1te2oxypmwgnHh7fXnGXcTZNEJ1rI081ds3+w== gitorious@hw01"
    np = DeployKey.find_by_key(nix_production_key)
    u   = User.find_by_username("zzet")

    p "Remove deploy keys".red
    DeployKeysProject.where(deploy_key_id: np).destroy_all if np

    p "Remove all Service::BuildFace".red
    Service::Nix.destroy_all

    Service.where(type: "GitlabCiService").delete_all
    Service.where(type: "CampfireService").delete_all
    Service.where(type: "HipchatService").delete_all

    p "Remove all ServiceKey like prod and staging".red
    ServiceKey.where(key: nix_production_key).destroy_all

    p "Create pattern services".green
    production_attrs = {
      title: "Nix production",
      description: "Nix service",
      active_state_event: "activate",
      public_state_event: "publish",
      service_type: "nix"
    }

    production_service  = Services::CreateContext.new(u, production_attrs).execute(:admin)

    npk = ServiceKey.create(title: "Nix production", key: nix_production_key)
    unless npk.valid?
      fingerprint = npk.fingerprint
      Key.where(fingerprint: fingerprint).destroy_all
      npk.save
    end

    production_service.service_key_service_relationships.create(service_key: npk, code_access_state: :clone)

    p "Migrate projects to new services".green

   ["backend-externals/faac", "backend-externals/x264", "backend-externals/x265", "backend/blue7",
   "backend/deligra", "backend/mlfoundation2", "backend/green6", "backend/mlfoundation",
   "backend/mlstreams", "backend/playout", "backend/mlstreams2", "backend/playout-grabber-status-client",
   "dvr/sdi-processor", "boosted/libboosted", "boosted/decklinksdk", "dvr/mzinin-libundevav",
   "dvr/mzinin-libdecklink", "dvr/vpp-stitcher", "nptv/clutter", "nptv/cogl", "nptv/gjs", "nptv/glib_sym",
   "nptv/img-compress", "nptv/nptv2", "nptv/protobufs", "nptv/ogre", "nptv/pynptv", "playout-backend-externals/ffmpeg",
   "playout-backend-externals/pl-faac", "playout-backend-externals/pl-gnustep-base", "playout-backend-externals/x264",
   "test/test", "video-stuff/video-validator", "videosearch/videosearch-alg-backend", "videosearch/recognition-framework",
   "negval/cmake-modules"].each do |project_name|
       project = Project.find_with_namespace(project_name)
       if project.present?
         print "Work with #{project_name}".yellow
         print " ... "

         project_production_service = Projects::Services::ImportContext.new(u, project, production_service).execute

         print "imported".green
         print " ... "

         project_production_service.enable  unless project_production_service.enabled?
         p "enabled".green
       else
         p "Work with #{project_name} filed - no project - no work".red
       end
     end
  end
end
