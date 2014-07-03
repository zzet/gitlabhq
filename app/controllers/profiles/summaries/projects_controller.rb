class Profiles::Summaries::ProjectsController < Profiles::Summaries::ApplicationController
  def create
    project_ids = params[:project_ids].respond_to?(:each) ? params[:project_ids] : params[:project_ids].split(',')
    project_ids.each do |project_id|
      relation = summary.summary_entity_relationships.new
      relation.entity_id = project_id
      relation.entity_type = Project.name
      relation.save
    end
    redirect_to edit_profile_summary_path(summary)
  end

  def update
    relation = summary.summary_entity_relationships.find(params[:id])

    opts, options = extract_options(Project, params)

    relation.update_attributes({ options: opts, options_actions: options })

    redirect_to edit_profile_summary_path(summary)
  end

  def destroy
    relation = summary.summary_entity_relationships.find_by(id: params[:id])
    relation.destroy if relation
    redirect_to edit_profile_summary_path(summary)
  end
end
