class Profiles::SummariesController < Profiles::ApplicationController
  def index
    @summaries = Event::Summary.order(created_at: :asc)
  end

  def new
    @summary = current_user.summaries.new
  end

  def create
    @summary = current_user.summaries.new(params[:event_summary])
    binding.pry
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
    current_user.summaries.find_each do |summary|
      current_time = Time.zone.now

      subscriber = summary.user
      settings = subscriber.notification_setting
      next if settings.blank? || !settings.brave

      events = summary.events_for(current_time)
      next if events.blank?

      EventSummaryMailer.daily_digest(summary.user.id, events.map(&:id), summary.id, current_time).deliver!

      summary.last_send_date = current_time
      summary.save
    end
    redirect_to profile_summaries_path
  end
end
