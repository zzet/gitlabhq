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
      redirect_to edit_profile_summary_path(@summary)
    else
      render 'new'
    end
  end

  def edit
    @summary = current_user.summaries.find(params[:id])
    @summary_entities = @summary.summary_entity_relationships.order(created_at: :asc).group_by(&:entity_type)
  end

  def show
    @summary = current_user.summaries.find(params[:id])
  end

  def destroy
    @summary = current_user.summaries.find(params[:id])
    @summary.destroy
    redirect_to profile_summaries_path
  end

  def update
    @summary = current_user.summaries.find(params[:id])
    @summary.update_attributes(params[:event_summary])
    redirect_to edit_profile_summary_path(@summary)
  end

  def send_now
    summary = current_user.summaries.find(params[:id])
    current_time = Time.zone.now

    events = summary.events_for(current_time)

    if events.any?

      case summary.period.to_sym
      when :daily
        EventSummaryMailer.daily_digest(summary.user.id, events.map(&:id), summary.id, current_time).deliver!
      when :weekly
        EventSummaryMailer.weekly_digest(summary.user.id, events.map(&:id), summary.id, current_time).deliver!
      when :monthly
        EventSummaryMailer.monthly_digest(summary.user.id, events.map(&:id), summary.id, current_time).deliver!
      end

      summary.last_send_date = current_time
      summary.save
    end

    redirect_to profile_summaries_path
  end
end
