class Projects::CiBuildsController < Projects::ApplicationController
  def show
    render text: build.trace, content_type: 'text/plain'
  end

  def rebuild
    build.to_build
    build.save
    build.run

    render layout: false
  end

  private

  def build
    @build ||= project.jenkins_ci.builds.find(params[:id])
  end
end
