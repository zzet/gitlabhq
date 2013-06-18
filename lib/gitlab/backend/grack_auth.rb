require_relative 'shell_env'
require_relative 'grack_ldap'
require_relative 'grack_helpers'

module Grack
  class Auth < Rack::Auth::Basic
    include LDAP
    include Helpers

    attr_accessor :user, :project, :ref, :env

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      @auth = Request.new(env)

      # Need this patch due to the rails mount
      @env['PATH_INFO'] = @request.path
      @env['SCRIPT_NAME'] = ""

      auth!
    end

    private

    def auth!
      return render_not_found unless project

      if @auth.provided?
        return bad_request unless @auth.basic?

        # Authentication with username and password
        login, password = @auth.credentials

        @user = authenticate_user(login, password)

        if @user
          Gitlab::ShellEnv.set_env(@user)
          @env['REMOTE_USER'] = @auth.username
        else
          return unauthorized
        end

      else
        return unauthorized unless project.public
      end

      if authorized_git_request?
        @app.call(env)
      else
        unauthorized
      end
    end

    def authorized_git_request?
      # Git upload and receive
      if @request.get?
        authorize_request(@request.params['service'])
      elsif @request.post?
        authorize_request(File.basename(@request.path))
      else
        false
      end
    end

    def authenticate_user(login, password)
      user = User.find_by_email(login) || User.find_by_username(login)

      # If the provided login was not a known email or username
      # then user is nil
      if user.nil? || user.ldap_user?
        # Second chance - try LDAP authentication
        return nil unless ldap_conf.enabled

        auth = Gitlab::Auth.new
        auth.ldap_auth(login, password)
      else
        return user if user.valid_password?(password)
      end
    end

    def authorize_request(service)
      case service
      when 'git-upload-pack'
        project.public || can?(user, :download_code, project)
      when'git-receive-pack'
        action = if project.protected_branch?(ref)
                   :push_code_to_protected_branches
                 else
                   :push_code
                 end

        can?(user, action, project)
      else
        false
      end
    end

    def project
      @project ||= project_by_path(@request.path_info)
    end

    def ref
      @ref ||= parse_ref
    end

    def parse_ref
      input = if @env["HTTP_CONTENT_ENCODING"] =~ /gzip/
                Zlib::GzipReader.new(@request.body).read
              else
                @request.body.read
              end

      # Need to reset seek point
      @request.body.rewind
      /refs\/heads\/([\w\.-]+)/n.match(input.force_encoding('ascii-8bit')).to_a.last
    end
  end
end
