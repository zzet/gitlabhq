class Profiles::Summaries::ApplicationController < Profiles::ApplicationController

  def summary
    @summary ||= Event::Summary.find(params[:summary_id])
  end
end
