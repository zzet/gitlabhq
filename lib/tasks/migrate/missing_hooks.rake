desc "GITLAB | add missing hooks for broken repositories"
task add_missing_hooks: :environment do
  puts "Adding missing hooks for repositories without then(for some reason)"

  Project.find_each do |project|
    path = project.repository.path
    hooks_path = File.join(path, 'hooks')

    unless File.exist?(hooks_path)
      path_to_shell = '/rest/u/apps/gitlab-shell/current'
      File.symlink(File.join(path_to_shell, 'hooks'), hooks_path)
    end
  end
end
