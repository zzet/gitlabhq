class EventsController < ApplicationController
  before_filter :event_filter, only: :index
  layout false

  def index
    if params[:parent_event_id]
      @events = Event.where(parent_event_id: params[:parent_event_id],
                            target_type: params[:dashboard])
    else
      @events = []
    end
  end
end
