Airbrake.configure do |config|
  config.api_key = 'fc385eb21b2f7c7e8532d1ec3d0179cf'
  config.host    = 'errbit.undev.cc'
  config.port    = 80
  config.secure  = config.port == 443
end
