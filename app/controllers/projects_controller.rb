class ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show]
  before_filter :project, except: [:new, :create]
  before_filter :repository, except: [:new, :create]

  # Authorize
  before_filter :authorize_read_project!, except: [:index, :new, :create]
  before_filter :authorize_admin_project!, only: [:edit, :update, :destroy, :transfer, :archive, :unarchive, :retry_import]
  before_filter :require_non_empty_project, only: [:blob, :tree, :graph]

  layout 'navless', only: [:new, :create, :fork]
  before_filter :set_title, only: [:new, :create]
  before_filter :event_filter, only: :show

  rescue_from CarrierWave::IntegrityError, with: :invalid_file

  def new
    @project = Project.new
  end

  def edit
    check_git_protocol
    render 'edit', layout: "project_settings"
  end

  def create
    @project = ::ProjectsService.new(current_user, params[:project]).create
    flash[:notice] = 'Project was successfully created.' if @project.saved?

    respond_to do |format|
      format.js
    end
  end

  def update
    status = ::ProjectsService.new(current_user, @project, params).update

    respond_to do |format|
      if status
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to edit_project_path(@project), notice: 'Project was successfully updated.' }
        format.js
      else
        format.html { render "edit", layout: "project_settings" }
        format.js
      end
    end
  end

  def transfer
    ::ProjectsService.new(current_user, project, params).transfer
  end

  def show
    if @project.import_in_progress?
      redirect_to import_project_path(@project)
      return
    end

    return authenticate_user! unless @project.public? || current_user

    check_git_protocol

    limit = (params[:limit] || 20).to_i

    @dashboard = @project.class
    @events = Event.for_dashboard(@project)
    @events = @event_filter.apply_filter(@events) if (@event_filter.params - %w(team group)).any?
    @events = @events.limit(limit).offset(params[:offset] || 0).recent

    @owners     = @project.team.owners
    @masters    = @project.team.masters     - @owners
    @developers = @project.team.developers  - (@owners + @masters)
    @reporters  = @project.team.reporters   - (@owners + @masters + @developers)
    @guests     = @project.team.guests      - (@owners + @masters + @developers + @reporters)

    @members_count = @owners.count + @masters.count + @developers.count + @reporters.count + @guests.count

    @teams = (@project.teams + @project.group_teams).uniq

    @gitlab_ci_service  = @project.services.where(type: Service::GitlabCi).first
    @build_face_service = @project.services.where(type: Service::BuildFace).first

    respond_to do |format|
      format.html do
        if @project.empty_repo?
          render "projects/empty", layout: user_layout
        else
          @last_push = current_user.recent_push(@project.id) if current_user
          render :show, layout: user_layout
        end
      end
      format.json { pager_json("events/_events", @events.count) }
    end
  end

  def import
    if project.import_finished?
      redirect_to @project
      return
    end
  end

  def retry_import
    unless @project.import_failed?
      redirect_to import_project_path(@project)
    end

    @project.import_url = params[:project][:import_url]

    if @project.save
      @project.reload
      @project.import_retry
    end

    redirect_to import_project_path(@project)
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, project)

    group = project.group
    ::ProjectsService.new(current_user, project, params).delete

    respond_to do |format|
      format.html { redirect_to group.present? ? group_path(group) : root_path }
    end
  end

  def fork
    @forked_project = ::ProjectsService.new(current_user, project).fork

    respond_to do |format|
      format.html do
        if @forked_project.saved? && @forked_project.forked?
          redirect_to(@forked_project, notice: 'Project was successfully forked.')
        else
          @title = 'Fork project'
          render "fork"
        end
      end
      format.js
    end
  end

  def autocomplete_sources
    note_type = params['type']
    note_id = params['type_id']
    participating = if note_type && note_id
                      participants_in(note_type, note_id)
                    else
                      []
                    end
    team_members = sorted(@project.team.members)
    participants = team_members + participating
    @suggestions = {
      emojis: Emoji.names.map { |e| { name: e, path: view_context.image_url("emoji/#{e}.png") } },
      issues: @project.issues.select([:iid, :title, :description]),
      mergerequests: @project.merge_requests.select([:iid, :title, :description]),
      members: participants.uniq
    }

    respond_to do |format|
      format.json { render json: @suggestions }
    end
  end

  def archive
    return access_denied! unless can?(current_user, :archive_project, project)
    project.archive!

    respond_to do |format|
      format.html { redirect_to @project }
    end
  end

  def unarchive
    return access_denied! unless can?(current_user, :archive_project, project)
    project.unarchive!

    respond_to do |format|
      format.html { redirect_to @project }
    end
  end

  def upload_image
    link_to_image = ::Projects::ImageService.new(repository, params, root_url).execute

    respond_to do |format|
      if link_to_image
        format.json { render json: { link: link_to_image } }
      else
        format.json { render json: "Invalid file.", status: :unprocessable_entity }
      end
    end
  end

  protected

  def check_git_protocol
    @git_protocol_enabled ||= Gitlab.config.gitlab.git_daemon_enabled
  end

  private

  def upload_path
    base_dir = FileUploader.generate_dir
    File.join(repository.path_with_namespace, base_dir)
  end

  def accepted_images
    %w(png jpg jpeg gif)
  end

  def invalid_file(error)
    render json: { message: error.message }, status: :internal_server_error
  end

  def set_title
    @title = 'New Project'
  end

  def user_layout
    current_user ? "projects" : "public_projects"
  end

  def participants_in(type, id)
    users = case type
            when "Issue"
              issue = @project.issues.find_by_iid(id)
              issue ? issue.participants : []
            when "MergeRequest"
              merge_request = @project.merge_requests.find_by_iid(id)
              merge_request ? merge_request.participants : []
            when "Commit"
              author_ids = Note.for_commit_id(id).pluck(:author_id).uniq
              User.where(id: author_ids)
            else
              []
            end
    sorted(users)
  end

  def sorted(users)
    users.uniq.compact.sort_by(&:username).map { |user| { username: user.username, name: user.name } }
  end
end
