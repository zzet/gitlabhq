class Profiles::Summaries::UsersController < Profiles::Summaries::ApplicationController
  def create
    user_ids = params[:user_ids].respond_to?(:each) ? params[:user_ids] : params[:user_ids].split(',')
    user_ids.each do |user_id|
      relation = summary.summary_entity_relationships.new
      relation.entity_id = user_id
      relation.entity_type = User.name
      relation.save
    end
    redirect_to edit_profile_summary_path(summary)
  end

  def update
    relation = summary.summary_entity_relationships.find(params[:id])
    options = begin
                params[:event_summary_entity_relationship][:options].keep_if do |option|
                  User.watched_sources.include?(option.to_sym)
                end
              rescue
                []
              end
    relation.update_attributes({options: options})
    redirect_to edit_profile_summary_path(summary)
  end

  def destroy
    relation = summary.summary_entity_relationships.find_by(id: params[:id])
    relation.destroy if relation
    redirect_to edit_profile_summary_path(summary)
  end
end
