class Profiles::Summaries::GroupsController < Profiles::Summaries::ApplicationController
  def create
    group_ids = params[:group_ids].respond_to?(:each) ? params[:group_ids] : params[:group_ids].split(',')
    group_ids.each do |group_id|
      relation = summary.summary_entity_relationships.new
      relation.entity_id = group_id
      relation.entity_type = Group.name
      relation.save
    end
    redirect_to edit_profile_summary_path(summary)
  end

  def update
    relation = summary.summary_entity_relationships.find(params[:id])

    opts, options = extract_options(Group, params)

    relation.update_attributes({ options: opts, options_actions: options })

    redirect_to edit_profile_summary_path(summary)
  end

  def destroy
    relation = summary.summary_entity_relationships.find_by(id: params[:id])
    relation.destroy if relation
    redirect_to edit_profile_summary_path(summary)
  end
end
