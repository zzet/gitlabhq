namespace :undev do
  desc "Undev | migrate exist projects to redmine service"
  task migrate_to_redmine: :environment do

    ActiveRecord::Base.redmineervers.disable(:all)

    redmine_production_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArAqshTNeuBeRaGZle86N/zvql0YncCqqZIOV2yWJ0I7lmnxQhCr6GF65ljhBjm9djNdM+dXi1fbIiEv7EGXxrzlQnN4EDkaHSIGejhOySoPBnCrHVsCdkvFzC05drYmehtQmMSjCU6oddJEDzzIaoWLQEuqF/YffHu4Xy4XGotAduK36ViJ79v77hvcksdrw7Ki/LFh0z9ZOEkuFfjgzjWK43V9o65RxFt7g8yLoyuyyP3s5SSNS6CF74/tom5TZBjpzAs71LVx7mejrpChRZpgCXF5AopYU05ecZEKC6rIB0SMscgs53vtdx1fjFX7ntgm2FznQQH3EXe/tPIqLhQ== redmine@hw01"

    op = DeployKey.find_by_key(redmine_production_key)
    u   = User.find_by_username("zzet")

    p "Remove deploy keys".red
    DeployKeysProject.where(deploy_key_id: op).destroy_all if op

    p "Remove all Service::Redmine".red
    Service::Redmine.destroy_all

    p "Remove all ServiceKey like prod and staging".red
    ServiceKey.where(key: redmine_production_key).destroy_all

    p "Create pattern services".green
    production_attrs = {
      title: "Redmine PM",
      description: "Redmine service",
      active_state_event: "activate",
      public_state_event: "publish",
      service_type: "redmine"
    }

    production_service  = Services::CreateContext.new(u, production_attrs).execute(:admin)

    opk = ServiceKey.create(title: "Redmine production", key: redmine_production_key)
    unless opk.valid?
      fingerprint = opk.fingerprint
      Key.where(fingerprint: fingerprint).destroy_all
      opk.save
    end

    production_service.service_key_service_relationships.create(service_key: opk, code_access_state: :clone)

    p "Migrate projects to new services".green

    ["admon-ror/admon-func-tests", "admon-ror/admon-mobile-api", "admon-ror/admon-replicator", "admon-ror/admon-reports",
     "admon-ror/admon-ror", "admon-ror/commercial-break-android", "admon-ror/commercial-break-bada", "admon-ror/commercial-break-ios",
     "admon-ror/platform", "ads/ads", "adv/mediamarktad-chi-sfk-apps", "airports/airport_widgets", "alehinmemorial/alehinmemorial",
     "backend/backend", "backend/backstage-cutter", "backend/blue7", "backend/brida-configs", "backend/brida-face",
     "backend/brida", "backend/brida2", "backend/brida_face_client", "backend/decklink-grabber", "backend/deligra",
     "backend/g6-balancer", "backend/g6-stats", "backend/green6", "backend/grida", "backend/hls", "backend/lander",
     "backend/mlfoundation", "backend/mlfoundation2", "backend/mlstreams", "backend/mlstreams2", "backend/playout",
     "backend/pyhls", "backend/testing-playout", "backend/zb-frontend", "baran-info/baran-info", "bloom/bloom",
     "bordeaux/bordeaux", "bordeaux/dispatcher", "bordeaux/dispatcherl", "bordeaux/pusher", "cctv/survapps", "cctv/telecircuit",
     "chess/chess", "cutting-room/markapp-core", "demo-europe/demo-europe", "digicast/digicast_rails", "digital-october/digital-october-plug",
     "digital-october/digitaloctober", "digital-october/dotv", "digital-october/lint", "digital-october/live-translations",
     "digital-october/new_digitaloctober", "digital-october/techcrunch-2013-siberia", "digital-october/techcrunch-2013",
     "double-fm/double-fm-site", "dvr/dvr-backend", "dvr/dvr-storage", "dvr/mzinin-libundevav", "dvr/sdi-processor", "dvr/vpp-stitcher",
     "elections-ua/nettops-chef", "elections-ua/servers-chef", "eurosport-wtcc/wtcc-cc", "eurosport-wtcc/wtcc-sfk-apps", "flash-player/player_2",
     "football/football-cc", "forums/forumspb", "forums/forumspb_rails", "generations/generations", "hiresite/hiresite", "ibc-epg/epg-backend-apps",
     "ibc-epg/epg-sfk-apps", "ibc-simpletv/simpletv-sfk-apps", "infrastructure/build-face", "infrastructure/chef-repo",
     "infrastructure/errbit", "infrastructure/gitlab", "infrastructure/gitorious", "infrastructure/js_exceptions", "infrastructure/redmine",
     "infrastructure/redmine_changeset_branch", "infrastructure/redmine_close_button", "infrastructure/redmine_stepashka_fu", "infrastructure/redmine_tagging",
     "infrastructure/runit-man", "infrastructure/testlink", "infrastructure/undev", "inpicture-video-marking/object_app",
     "inpicture-video-marking/win32-client-app", "ivacy/fall-2011", "kappa/kappa", "kazan2013/kazamon", "knowledge-stream/knowledge-stream",
     "ktv-ios/kommersant_club", "looky/looky-ios", "mail-ru-projects/rus-code-cup-2013", "mailer/mailer", "media-breach/mb-tv-monitor",
     "media-breach/mb-website", "mega-highload-platform/android-voting-broadcast", "mega-highload-platform/baida-nettops",
     "mega-highload-platform/bench-voting-stations-site", "mega-highload-platform/elections-exporter-site", "mega-highload-platform/grabber-bootstrap",
     "mega-highload-platform/grabber-js-face", "mega-highload-platform/grabber-setup-ss", "mega-highload-platform/grafsm",
     "mega-highload-platform/nettops-chef", "mega-highload-platform/nettops-selfupdate", "mega-highload-platform/server-bootstrap",
     "mega-highload-platform/voting-broadcast-site", "mega-highload-platform/voting-stations-db", "mega-highload-platform/vs-admin-face",
     "mega-highload-platform/yandex-coords-tile-generator", "mega-highload-platform/yaqtface", "megaadmins/chef", "megaadmins/zabbix-plugins",
     "minaev/minaev", "minaev/minaev_v2", "mipacademy/mipacademy", "moscowfm/moscowfm-android", "moscowfm/moscowfm-bada", "moscowfm/moscowfm-ios",
     "moscowfm/moscowfm-wp7", "nptv-cloud/entry-point-resolver", "nptv-demo-apps/football-prototype-sfk-apps", "nptv-demo-apps/knowledgestream-backend-apps",
     "nptv-demo-apps/knowledgestream-sfk-apps", "nptv-players/nptv-android-player", "nptv-players/nptv-appletv-player", "nptv-players/nptv-linux-vdpau-player",
     "nptv-players/nptv-wp7-player", "nptv-simply-tv/simplytv-backend-apps", "nptv-simply-tv/simplytv-sfk-apps", "nptv-simply-tv/simplytv-sfknet-epg",
     "nptv-web-infrastructure/app-store", "nptv-web-infrastructure/face", "nptv-web-infrastructure/userbase-next", "nptv-web-infrastructure/userbase-united",
     "nptv-web-infrastructure/userbase_admin", "nptv/billing", "nptv/cas-server", "nptv/dev-center", "nptv/face", "nptv/mediastorage-master",
     "nptv/morphing-core", "nptv/movies_db", "nptv/nettops-chef", "nptv/nptv-billing", "nptv/nptv-net-sdk", "nptv/nptv2", "nptv/oa-userbase",
     "nptv/oskb-demohost-sfk-apps", "nptv/oskb-sfk-apps", "nptv/protobufs", "nptv/renderwidgets", "nptv/screen-test", "nptv/sfk-analytics-agent",
     "nptv/sfk-analytics", "nptv/sfk-apps", "nptv/sfk-homescreen", "nptv/sfk", "nptv/statistics-native", "nptv/statistics", "nptv/tickers-api",
     "nptv/ub-balance", "nptv/userbase", "nptv/userbase_client", "olymp-tv/control-center", "olymp-tv/olymp-sfk-apps", "olympics2013/olympictorch",
     "party_billing/party_billing", "petrolich/iron_daemon", "rbc-tv/backend-rbc-tv", "rbc-tv/sfk-rbc-tv", "receipts/image-processing",
     "receipts/main", "receipts/mobile", "receipts/mobile_client", "receipts/ocr", "receipts/photos", "redmine-plugins/redmine_undev_watchers",
     "rubricator/catagent", "rubricator/catstore-pumpkin", "rubricator/catstore", "ruby-sfk-stuff/sfk-homescreen2", "rzdtv/ctv",
     "small-things/watch-tower", "sochi-2014/control-center", "spief/business-contact-manager", "spief/control-center", "spief/sfk-apps",
     "spief/spief2013-nettops-chef", "storage/vstore-face", "storage/vstore", "teleguide/teleguide-client", "teleguide/teleguide-downloader",
     "teleguide/teleguide-face", "teleguide/tvgrid-downloader", "teleguide/vida-downloader", "telemarker-search/sphinxing-think", "telemarker-search/telemarker-search",
     "telemarker/telemarker-func-tests", "telemarker/telemarker-sfk-apps", "telemarker/telemarker", "telemarker/tm-admin", "televizor/televizor",
     "tv-market/tv-market", "verm666-project-2/verm666-project", "zbb-frontend/zbb-pad", "zh/crtmpserver", "zh/dracaena", "zh/erlang-libtorrent",
     "zh/erlang-mogilefs", "zh/etorrent", "zh/fansite", "zh/flash", "zh/grabber", "zh/logmachine", "zh/rtmpdump", "zh/sbman", "zh/swamp",
     "zh/torrent-client", "zh/zgrabber", "zh/zh-config", "zh/zhsite", "zh/zlogger", "zh/zplayer", "digital-october/apimoscow"].each do |project_name|
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
