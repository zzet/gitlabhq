namespace :gitlab do
  desc "GITLAB | Migrate Groups to match v6.0"
  task migrate_groups: :environment do
    puts "This will add group owners to group membership"
    #ask_to_continue

    Group.find_each(batch_size: 20) do |group|
      begin
        group.send :add_owner
        print '.'
      rescue => ex
        puts ex.message
        print 'F'
      end
    end
  end

  desc "GITLAB | Migrate Global Projects to Namespaces"
  task migrate_global_projects: :environment do
    found = Project.where(namespace_id: nil).count
    if found > 0
      puts "Global namespace is deprecated. We found #{found} projects stored in global namespace".yellow
      puts "You may abort this task and move them to group/user namespaces manually."
      puts "If you want us to move this projects under owner namespaces then continue"
      #ask_to_continue
    else
      puts "No global projects found. Proceed with update.".green
    end

    Project.where(namespace_id: nil).find_each(batch_size: 20) do |project|
      begin
        project.transfer(project.owner.namespace)
        print '.'
      rescue => ex
        puts ex.message
        print 'F'
      end
    end
  end


  desc "GITLAB | Migrate inline notes"
  task migrate_inline_notes: :environment do
    Note.where('line_code IS NOT NULL').find_each(batch_size: 100) do |note|
      begin
        note.set_diff
        if note.save
          print '.'
        else
          print 'F'
        end
      rescue
        print 'F'
      end
    end
  end

  desc "GITLAB | Migrate SSH Keys"
  task migrate_keys: :environment do
    puts "This will add fingerprint to ssh keys in db"
    puts "If you have duplicate keys https://github.com/gitlabhq/gitlabhq/issues/4453 all but the first will be deleted".yellow
    #ask_to_continue

    Key.find_each(batch_size: 20) do |key|
      if key.valid? && key.save
        print '.'
      elsif key.fingerprint.present?
        puts "\nDeleting #{key.inspect}".yellow
        key.destroy
      else
        print 'F'
      end
    end
    print "\n"
  end


  desc "GITLAB | Migrate Milestones"
  task migrate_milestones: :environment do
    Milestone.where(state: nil).update_all(state: 'active')
  end

  # This taks will reload commits/diff for all merge requests
  desc "GITLAB | Migrate Merge Requests"
  task migrate_merge_requests: :environment do
    puts "Since 5.1 old merge request serialization logic was replaced with a better one."
    puts "It makes old merge request diff invalid for GitLab 5.1+"
    puts "* * *"
    puts "This will rebuild commits/diffs info for existing merge requests."
    puts "You will lose merge request diff if its already merged."
    #ask_to_continue

    MergeRequest.find_each(batch_size: 20) do |mr|
      mr.st_commits = []
      mr.save
      mr.reload_code
      print '.'
    end
  end

  desc "GITLAB | Migrate Note LineCode"
  task migrate_note_linecode: :environment do
    Note.inline.each do |note|
      index = note.diff_file_index
      if index =~ /^\d{1,10}$/ # is number. not hash.
        hash = Digest::SHA1.hexdigest(note.noteable.diffs[index.to_i].new_path)
        new_line_code = note.line_code.sub(index, hash)
        note.update_column :line_code, new_line_code
        print '.'
      end
    end
  end
end
