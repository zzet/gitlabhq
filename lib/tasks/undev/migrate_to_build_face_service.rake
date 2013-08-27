namespace :undev do
  desc "Undev | migrate exist projects to build face service"
  task :migrate_to_build_face do
   ["videosearch/videosearch-alg-backend", "infrastructure/pypiserver", "nptv-cloud/entry-point-resolver",
     "backend/pyhls-prefetcher", "nptv/nptv-xfonts", "storage/mogilefs-interesting-moments", "storage/state_of_minutes",
     "storage/mogilefs-resolver", "backend/front-tail", "infrastructure/mono", "infrastructure/puc",
     "playout-backend-externals/x264", "nvidia/nvenc-mp", "nptv-players/nptv-linux-vdpau-player", "backend/je", "kazan2013/kazamon",
     "mega-highload-platform/erltap", "playout-backend-externals/pl-gnustep-base", "backend-externals/ffmpeg", "backend-externals/gnustep-base",
     "backend-externals/gpac", "megaadmins/zabbix-plugins", "infrastructure/labarbara", "infrastructure/yandex-tank", "backend-externals/x264",
     "backend-externals/vlc", "mega-highload-platform/grafsm", "mega-highload-platform/grabber-js-face", "mega-highload-platform/antiflicker",
     "playout-backend-externals/pl-ffmpeg", "backend/lander", "backend/green6", "backend-externals/faac", "backend/decklink-grabber",
     "mega-highload-platform/elebal", "backend/blue7", "playout-backend-externals/pl-faac", "backend/playout", "nptv/nptv2",
     "mega-highload-platform/yaqtface", "backend/hlspd", "mega-highload-platform/pinger", "mega-highload-platform/varnish",
     "mega-highload-platform/vmod_ele_cfg", "backend/py-spif2", "storage/vstore", "backend/hls", "backend-externals/faad2",
     "bordeaux/dispatcherl", "infrastructure/askbot-setup", "nptv-players/nptv-desktop-player", "backend/screenshotline-ng-mogilefs",
     "backend/image-resizer-og-mogilefs", "playout-backend-externals/ffmpeg", "nptv/clutter", "testing-tools/chainrecoder", "storage/vstore-face",
     "dvr/vpp-stitcher", "LipovAnton/mytest", "mega-highload-platform/vmod_ele_cfg_centrals", "backend/pyhls", "backend/baker",
     "nptv-players/serialremote", "dvr/sdi-processor", "backend/deligra", "nptv-players/cubox-kernel", "nptv-players/takescreenshot",
     "nptv-players/xserver-xorg-video-dove", "backend/pos-api", "megaadmins/nginx-purge-cache", "userbase-next/zmq-forwarder", "ivaxer/gostatsd",
     "nptv-cloud/feedbackd", "nptv-cloud/render-weight", "backend/image_resizer_ng", "megaadmins/riemann-babbler-plugins",
     "megaadmins/deb-pkgs", "backend/encrequer", "nptv/nptv-net-sdk", "ibc-simplevod/simplevod-sfk-apps", "dvr/dvr-backend",
     "ibc-favorites/favorites-sfk-apps", "ibc-activity/activity-sfk-apps", "megaadmins/ohai-plugins", "megaadmins/yad",
     "nptv-cloud/ipvs-info", "ibc-weather-3d/weather-sfk-apps", "backend/minute_encoder", "backend/record-broker2",
     "backend/bsf_app", "rnd/networkremote"].each do |project_name|
       project = Project.find_with_namespace(project_name)
       project.create_build_face_service unless project.build_face_service.present?
       project.build_face_service.enable unless project.build_face_service.enabled?
       ProjectHook.where(url: "http://build-face.undev.cc/hooks").destroy_all
     end
  end
end
