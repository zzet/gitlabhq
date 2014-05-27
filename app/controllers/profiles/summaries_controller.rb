class Profiles::SummariesController < Profiles::ApplicationController
  def index
    @summaries = current_user.summaries.order(created_at: :asc)
  end

  def new
    @summary = current_user.summaries.new
  end

  def create
    @summary = current_user.summaries.new(params[:event_summary])
    if @summary.save
      redirect_to profile_summaries_path
    else
      render 'new'
    end
  end

  def edit
    @summary = Event::Summary.find(params[:id])
    @summary_entities = @summary.summary_entity_relationships.order(created_at: :asc).group_by(&:entity_type)
  end

  def show
    @summary = Event::Summary.find(params[:id])
  end

  def destroy
    @summary = Event::Summary.find(params[:id])
    @summary.destroy
    redirect_to profile_summaries_path
  end

  def update
    @summary = Event::Summary.find(params[:id])
    @summary.update_attributes(params[:event_summary])
    redirect_to profile_summaries_path
  end

  def send_now
    summary = current_user.summaries.find(params[:id])
    current_time = Time.zone.now

    events = summary.events_for(current_time)

    if events.any?

      EventSummaryMailer.daily_digest(summary.user.id, events.map(&:id), summary.id, current_time).deliver!

      summary.last_send_date = current_time
      summary.save
    end

    redirect_to profile_summaries_path
  end
end
