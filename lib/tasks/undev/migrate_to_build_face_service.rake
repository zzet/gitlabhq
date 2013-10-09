namespace :undev do
  desc "Undev | migrate exist projects to build face service"
  task migrate_to_build_face: :environment do

    build_face_production_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDq3hiE+hNaWsAHGXEWthfwcOznlQJ7n3mvk+oXpSp0JQ1KD4FNf8CodG8XvVXeLYvrbbpW/DSDrdrKRefbhAzdBUVhHDXHwuSafm9eGM3/3VX64osv85MPJZDz/F8iAnCtw8a4uqmHGU5ejU4jadqWnl2ajxlaOKJlnJihJSste1jWdSvwBGLYxnJDHw2bvDobVtmPATxF1/5MFYrBIP9sbreIBhpvPNa1joHyMI5dyTcAMSPHAjZL5amXUbVYsVnhgsmVjlWPG5Kh+1EEDxi+gqsZQ4kqyfsowA5imwlGO1iZbYCbhmfSyIX2O0Vhx0M/iEoVTVVf/aHaHYjGUkGp build-face@undev.ru"
    build_face_staging_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4rEGgT4ABE8DND5JvA0bYTAc9mNIjSVdwdodiWvfoaoibnI0KInfIke8oMMOfXJWXiWHFnta70jqs/RFjGPXDC06Y0lq2EUnIkzy9dwPSKOPXdCUYbDhg4d06o0xNMo6Nz9oO4zHPstRFDMhqAcdXhest4fFGZhtKTONUNXw3Ti6M34+ROwttniFQ3kuita62HBOjq8OYVQrwH7Mxj9AcUTL36OZ9stnotYg1TmmaIaNbANT1Iv89Ud2oMdpEvbQfIkMOw0U7uVLUOsItmaY+GrjJCWoYHn1rvY8iV7t9OoEB+aVmjjpX4407ZiQI7ZvquqWWxR5TXxbLrzLTozhn poweruser@buildface-staging-01"
    bfp = DeployKey.find_by_key(build_face_production_key)
    bfs = DeployKey.find_by_key(build_face_staging_key)
    u   = User.find_by_username("zzet")

    p "Remove deploy keys".red

    DeployKeysProject.where(deploy_key_id: [bfp.id, bfs.id]).destroy_all

    p "Remove project Hooks".red
    ProjectHook.where(url: "http://build-face.undev.cc/hooks").destroy_all

    p "Remove all Service::BuildFace".red
    Service::BuildFace.destroy_all

    production_attrs = {
      title: "Build Face production",
      description: "Build face service",
      active_state_event: "activate",
      public_state_event: "publish",
      configuration: {
        domain: "http://build-face.undev.cc",
        system_hook_path: "/hooks/gitlab",
        web_hook_path: "/hooks"
      }
    }

    staging_attrs = {
      title: "Build Face staging",
      description: "Build face service (staging)",
      active_state_event: "activate",
      public_state_event: "publish",
      configuration: {
        domain: "http://build-face-staging.undev.cc",
        system_hook_path: "/hooks/gitlab",
        web_hook_path: "/hooks"
      }
    }

    production_service  = Services::Context.new(u, production_attrs).execute(:admin)
    staging_service     = Services::Context.new(u, staging_attrs).execute(:admin)

    bfpk = ServiceKey.create(title: "Build Face production", key: build_face_production_key)
    bfsk = ServiceKey.create(title: "Build Face staging", key: build_face_staging_key)

    production_service.service_key_service_relationships.create(service_key_id: bfpk, sode_access_state: :clone)
    production_service.service_key_service_relationships.create(service_key_id: bfsk, sode_access_state: :clone)

   ["videosearch/videosearch-alg-backend","infrastructure/pypiserver","nptv-cloud/entry-point-resolver","backend/pyhls-prefetcher",
     "nptv/nptv-xfonts","storage/mogilefs-interesting-moments","storage/state_of_minutes","storage/mogilefs-resolver","backend/front-tail",
     "infrastructure/mono","infrastructure/puc","playout-backend-externals/x264","nvidia/nvenc-mp","nptv-players/nptv-linux-vdpau-player",
     "backend/je","kazan2013/kazamon","mega-highload-platform/erltap","playout-backend-externals/pl-gnustep-base","backend-externals/ffmpeg",
     "backend-externals/gnustep-base","backend-externals/gpac","megaadmins/zabbix-plugins","infrastructure/labarbara","infrastructure/yandex-tank",
     "backend-externals/x264","backend-externals/vlc","mega-highload-platform/grafsm","mega-highload-platform/grabber-js-face",
     "mega-highload-platform/antiflicker","playout-backend-externals/pl-ffmpeg","backend/lander","backend/green6","backend-externals/faac",
     "backend/decklink-grabber","mega-highload-platform/elebal","backend/blue7","playout-backend-externals/pl-faac","backend/playout","nptv/nptv2",
     "mega-highload-platform/yaqtface","backend/hlspd","mega-highload-platform/varnish","mega-highload-platform/vmod_ele_cfg","backend/py-spif2",
     "storage/vstore","backend/hls","backend-externals/faad2","bordeaux/dispatcherl","infrastructure/askbot-setup","nptv-players/nptv-desktop-player",
     "backend/screenshotline-ng-mogilefs","backend/image-resizer-og-mogilefs","playout-backend-externals/ffmpeg","nptv/clutter","testing-tools/chainrecoder",
     "storage/vstore-face","dvr/vpp-stitcher","LipovAnton/mytest","mega-highload-platform/vmod_ele_cfg_centrals","backend/pyhls","backend/baker",
     "nptv-players/serialremote","dvr/sdi-processor","backend/deligra","nptv-players/cubox-kernel","nptv-players/takescreenshot",
     "nptv-players/xserver-xorg-video-dove","backend/pos-api","megaadmins/nginx-purge-cache","userbase-next/zmq-forwarder","ivaxer/gostatsd",
     "nptv-cloud/feedbackd","nptv-cloud/render-weight","backend/image_resizer_ng","megaadmins/riemann-babbler-plugins","megaadmins/deb-pkgs",
     "backend/encrequer","nptv/nptv-net-sdk","ibc-simplevod/simplevod-sfk-apps","dvr/dvr-backend","ibc-favorites/favorites-sfk-apps",
     "ibc-activity/activity-sfk-apps","megaadmins/ohai-plugins","megaadmins/yad","nptv-cloud/ipvs-info","ibc-weather-3d/weather-sfk-apps",
     "backend/minute_encoder","backend/record-broker2","backend/bsf_app","rnd/networkremote","achernih/obs-macmini-6-2-test",
     "nptv-web-infrastructure/userbase_client","nptv-web-infrastructure/userbase_data","dvr/dvr-storage","megaadmins/slogd","megaadmins/nix-wrappers",
     "adv/mediamarktad-sfk-apps","nptv-demo-apps/effects-sfk-apps","video-stuff/video-validator","ashurpin/shining-dashboard","nptv-cloud/nptv-deploy-scripts",
     "snp_misc/hvr-driver-dkms","megaadmins/osd-info","nptv-cloud/bottle-washer","nptv-cloud/output-point","boosted/audiostreamer",
     "nptv-web-infrastructure/userbase-cas-authenticator","nptv/rengine-js-stdlib","nptv-web-infrastructure/cyber_lemmings"].each do |project_name|
       project = Project.find_with_namespace(project_name)
       if project.present?
         project_production_service = Projects::Services::ImportContext.new(u, project, production_service).execute
         project_staging_service    = Projects::Services::ImportContext.new(u, project, staging_service).execute

         project_production_service.enable  unless project_production_service.enabled?
         project_staging_service.enable     unless project_staging_service.enabled?
       end
     end
  end
end
