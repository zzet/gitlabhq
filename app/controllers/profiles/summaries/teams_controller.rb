class Profiles::Summaries::TeamsController < Profiles::Summaries::ApplicationController
  def create
    team_ids = params[:team_ids].respond_to?(:each) ? params[:team_ids] : params[:team_ids].split(',')
    team_ids.each do |team_id|
      relation = summary.summary_entity_relationships.new
      relation.entity_id = team_id
      relation.entity_type = Team.name
      relation.save
    end
    redirect_to edit_profile_summary_path(summary)
  end

  def update
    relation = summary.summary_entity_relationships.find(params[:id])

    opts, options = extract_options(Team, params)

    relation.update_attributes({ options: opts, options_actions: options })

    redirect_to edit_profile_summary_path(summary)
  end

  def destroy
    relation = summary.summary_entity_relationships.find_by(id: params[:id])
    relation.destroy if relation
    redirect_to edit_profile_summary_path(summary)
  end
end
