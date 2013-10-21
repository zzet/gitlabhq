namespace :undev do
  desc "Undev | migrate exist projects to obs service"
  task migrate_to_obs: :environment do

    ActiveRecord::Base.observers.disable(:all)

    obs_production_key = ""

    np = DeployKey.find_by_key(obs_production_key)
    u   = User.find_by_username("zzet")

    p "Remove deploy keys".red
    DeployKeysProject.where(deploy_key_id: np).destroy_all if np

    p "Remove all Service::Obs".red
    Service::Obs.destroy_all

    Service.where(type: "GitlabCiService").delete_all
    Service.where(type: "CampfireService").delete_all
    Service.where(type: "HipchatService").delete_all

    p "Remove all ServiceKey like prod and staging".red
    ServiceKey.where(key: obs_production_key).destroy_all

    p "Create pattern services".green
    production_attrs = {
      title: "Obs production",
      description: "Obs service",
      active_state_event: "activate",
      public_state_event: "publish",
      service_type: "obs"
    }

    production_service  = Services::CreateContext.new(u, production_attrs).execute(:admin)

    npk = ServiceKey.create(title: "Obs production", key: obs_production_key)
    unless bfpk.valid?
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
