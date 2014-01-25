gitlab_config_example_path = "#{Rails.root}config/gitlab.yml.example"
gitlab_config_custom_path = "#{Rails.root}config/gitlab.yml"

resque_config_example_path = "#{Rails.root}config/resque.yml.example"
resque_config_custom_path = "#{Rails.root}config/resque.yml"

aws_config_example_path = "#{Rails.root}config/aws.yml.example"
aws_config_custom_path = "#{Rails.root}config/aws.yml"

#gitlab_shell_config_example_path = "#{Rails.root}config/secret_keys.yml"
#gitlab_shell_config_custom_path = "#{Rails.root}config/secret_keys.yml"

Persey.init Rails.env do
  source :yaml, gitlab_config_example_path
  source :yaml, gitlab_config_custom_path

  source :yaml, resque_config_example_path, :resque
  source :yaml, resque_config_custom_path, :resque

  source :yaml, aws_config_example_path, :aws
  source :yaml, aws_config_custom_path, :aws


  env :production do
    gitlab_on_non_standard_port -> { ![443, 80].include?(gitlab.port.to_i) }
    host                        -> { gitlab.host }
    port                        -> { gitlab.https ? 443 : 80 }
    protocol                    -> { gitlab.https ? "https" : "http" }
    custom_port                 -> { gitlab_on_non_standard_port ? ":#{gitlab.port}" : nil}
    email_from                  -> { "gitlab@#{gitlab.host}" }
    relative_url_root           -> { gitlab.relative_url_root }
    url                         -> { "#{protocol}://#{host}#{custom_port}#{relative_url_root}" }
    satellites do
      path                      -> { File.expand(gitlab.satellites.path || "tmp/repo_satellites", Rails.root) }
    end
  end

  env :production, parent: :default
  env :develop, parent: :production

  env :test, parent: :develop do
    default_projects_limit    42
    default_can_create_group  false
    default_can_create_team   false
  end

  env :staging, parent: :production
end
