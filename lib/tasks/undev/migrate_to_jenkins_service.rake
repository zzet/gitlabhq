namespace :undev do
  desc "Undev | migrate exist projects to Jenkins service"
  task migrate_to_jenkins: :environment do

    ActiveRecord::Base.observers.disable(:all)

    jenkins_ci01_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDtz5bH9EQPHsPAkoPgi8IQGzDru0PGTHyL/srQWVV8jhTlGwdexWSJxtCf2gmxcGgQqals7j7xM0P2CFPi0Grv/8Xv3ZrAPT7BY9Z3aL2O/uwUw8COVRa2GczivZ8okg6rLCiG+4b2rderSJE+lllhnSk7FWLtvDtrS5RBcNeBcLQfZrtgva1Mu6+opzI0uwD4evZwg220DGHOI2LLbLE1e8uBws0JBChlTuCgpLIteYl1S1CJFY0F8+vLdOLMhPwWOVM9wiTqyaoNDX3uk2JGZVEpa25XiF+NVqIWD+7Ugbnj3yf9OfR/hQ/RE/b9vWnvP7mJ5xbycdJnN64dsNVD jenkins@ci01"
    jenkins_ci61_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4ow96YKXiL+uBHy9TAFW9s9hDmYUzIK2T04CQvlzqAdp81RGZIUqznhO9LhDtpXdRWh/ZEeD2dDp/vLScNKwKOTFOrUv8Gc8BzJyPLYH2ra6DtE2KV9fds+Y0GzvN5SYJwBCK54zOmy0mKRki/2OI/JTDNlQjKad0Uf2sQiHeIgE0jkMryUg2gJQXUKcPLGohohj2jIhBaqdqTSn1P5WcMdINZnGGWMKI+xhsyyZgyP5gi3BphPp0RyZoHJUAw/mtsSRnybA9BlrtEmwWSy/V6/53Nuj/isSHzdrYVuTpmSy2YXwDJu4OTERpeppnJhMuWfm4+lWZkXsP6s9o9TYr platform-testing@undev.ru"

    bfp = DeployKey.find_by_key(jenkins_ci61_key)
    bfs = DeployKey.find_by_key(jenkins_ci01_key)
    u   = User.find_by_username("zzet")

    p "Remove deploy keys".red
    DeployKeysProject.where(deploy_key_id: bfp).destroy_all if bfp
    DeployKeysProject.where(deploy_key_id: bfs).destroy_all if bfs

    p "Remove all Service::Jenkins".red
    Service::Jenkins.destroy_all

    Service.where(type: "GitlabCiService").delete_all
    Service.where(type: "CampfireService").delete_all
    Service.where(type: "HipchatService").delete_all

    p "Remove all ServiceKey like prod and staging".red
    ServiceKey.where(key: jenkins_ci01_key).destroy_all
    ServiceKey.where(key: jenkins_ci61_key).destroy_all

    p "Create pattern services".green
    ci01_attrs = {
      title: "Jenkins CI01",
      description: "Jenkins ci01 service",
      active_state_event: "activate",
      public_state_event: "publish",
      service_type: "jenkins"
    }

    ci61_attrs = {
      title: "Jenkins CI61",
      description: "Jenkins ci61 service",
      active_state_event: "activate",
      public_state_event: "publish",
      service_type: "jenkins"
    }

    ci01_service  = Services::CreateContext.new(u, ci01_attrs).execute(:admin)
    ci61_service  = Services::CreateContext.new(u, ci61_attrs).execute(:admin)

    bfpk = ServiceKey.create(title: "Jenkins ci01", key: jenkins_ci01_key)
    unless bfpk.valid?
      fingerprint = bfpk.fingerprint
      Key.where(fingerprint: fingerprint).destroy_all
      bfpk.save
    end

    bfsk = ServiceKey.create(title: "Jenkins ci61", key: jenkins_ci61_key)
    unless bfsk.valid?
      fingerprint = bfsk.fingerprint
      Key.where(fingerpint: fingerprint).destroy_all
      bfsk.save
    end

    ci01_service.service_key_service_relationships.create(service_key: bfpk, code_access_state: :clone)
    ci61_service.service_key_service_relationships.create(service_key: bfsk, code_access_state: :clone)

    p "Migrate projects to new services".green

    ["admon-ror/admon-func-tests",
      "admon-ror/admon-music-func-tests",
      "admon-ror/admon-ror",
      "admon-ror/audiotag",
      "ads/ads",
      "alehinmemorial/alehinmemorial",
      "Andrew8xx8/jenkins-integration-test",
      "backend/blue7",
      "backend/playout",
      "baran-info/baran-info",
      "bloom/bloom",
      "bordeaux/bordeaux",
      "cctv/survapps",
      "cctv/telecircuit",
      "chess/chess",
      "demo-europe/demo-europe",
      "digicast/digicast_rails",
      "digital-october/dotv",
      "digital-october/new_digitaloctober",
      "eurosport-wtcc/wtcc-cc",
      "eurosport-wtcc/wtcc-sfk-apps",
      "forums/forumspb_rails",
      "generations/generations",
      "ibc-epg/epg-sfk-apps",
      "ibc-favorites/favorites_backend_client",
      "ibc-simpletv/simpletv-backend",
      "ibc-simpletv/simpletv-sfk-apps",
      "infrastructure/build-face",
      "infrastructure/redmine",
      "inpicture-video-marking/inpicture-sfk-apps",
      "inpicture-video-marking/movie_sources_proxy",
      "inpicture-video-marking/win32-client-app",
      "kaliningrad/koroche",
      "kappa/kappa",
      "knowledge-stream/knowledge-stream",
      "ktv-ios/kommersant_club",
      "ktv-ios/web_admin",
      "live_site/live_site",
      "mailer/mailer",
      "media-breach/mb-tv-monitor",
      "megaadmins/ik-chef-clean",
      "mega-highload-platform/elections-exporter-site",
      "mega-highload-platform/vs-admin-face",
      "mega-highload-platform/yandex-coords-tile-generator",
      "mipacademy/mipacademy",
      "mtip/mtip",
      "music-test/music-test",
      "nptv/billing",
      "nptv-demo-apps/football-prototype-sfk-apps",
      "nptv-demo-apps/knowledgestream-sfk-apps",
      "nptv/dev-center",
      "nptv/face",
      "nptv/oskb-sfk-apps",
      "nptv/sandbox-c",
      "nptv/sfk-apps",
      "nptv/sfk-bootstrap-example",
      "nptv/sfk-bootstrap",
      "nptv/sfk",
      "nptv/sfk-http",
      "nptv/sfk-i18n",
      "nptv/sfk-models",
      "nptv/sfk-rspec",
      "nptv/sfk-templates",
      "nptv-simply-tv/simplytv-sfk-apps",
      "nptv/userbase",
      "olympics2013/olympictorch",
      "party_billing/party_billing",
      "petrolich/iron_daemon",
      "rbc-tv/backend-rbc-tv",
      "rbc-tv/sfk-rbc-tv",
      "receipts/main",
      "rubricator/catagent",
      "rubricator/catstore",
      "rzdtv/ctv",
      "rzdtv/ingest",
      "rzdtv/requestmanager",
      "rzdtv/sql_notification",
      "spief/business-contact-manager",
      "spief/sfk-apps",
      "storage/net-client",
      "teleguide/teleguide-client",
      "teleguide/teleguide-face",
      "teleguide/tvgrid-downloader",
      "telemarker-search/yafts_client",
      "telemarker/telemarker-func-tests",
      "telemarker/telemarker",
      "telemarker/tm-admin",
      "testing-tools/api_testing_lib",
      "testing-tools/api_testing_service",
      "testing-tools/platform-kazan-tests",
      "testing-tools/platform-playout-test",
      "testing-tools/platform-spief-tests",
      "test-project-for-continuous-integration/test-project-for-continuous-integration",
      "tv-market/tv-market",
      "z34/z34",
      "zh/fansite",
      "zh/zhsite",
      "cctv/survapps",
      "ibc-favorites/favorites-backend",
      "spief/business-contact-manager",
      "Yakshankin/contentup_acceptance_testing"].each do |project_name|
      project = Project.find_with_namespace(project_name)
      if project.present?
        print "Work with #{project_name}".yellow
        print " ... "

        project_production_service = Projects::Services::ImportContext.new(u, project, ci01_service).execute

        print "imported".green
        print " ... "

        project_production_service.enable  unless project_production_service.enabled?
        p "enabled".green
      else
        p "Work with #{project_name} filed - no project - no work".red
      end
    end


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

        project_production_service = Projects::Services::ImportContext.new(u, project, ci61_service).execute

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
