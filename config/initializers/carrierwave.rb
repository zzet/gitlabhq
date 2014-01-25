CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/

if Gitlab.config.aws.enabled

  CarrierWave.configure do |config|
    config.fog_credentials = {
      provider: 'AWS',                                        # required
      aws_access_key_id: Gitlab.config.aws.access_key_id,         # required
      aws_secret_access_key: Gitlab.config.aws.secret_access_key, # required
      region: Gitlab.config.aws.region,                           # optional, defaults to 'us-east-1'
    }
    config.fog_directory  = Gitlab.config.aws.bucket                    # required
    config.fog_public     = false                                   # optional, defaults to true
    config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
    config.fog_authenticated_url_expiration = 1 << 29               # optional time (in seconds) that authenticated urls will be valid.
                                                                    # when fog_public is false and provider is AWS or Google, defaults to 600
  end
end
