class UpdateEventCommentedRelatedToCurrentEntity < ActiveRecord::Migration
  def up
    ActiveRecord::Base.observers.disable :all
    Event.where(action: :commented_related).find_each do |event|
      event.update_attribute(action: :commented_merge_request) if event.source.noteable.present? && event.source.noteable.is_a?(MergeRequest)
      event.update_attribute(action: :commented_issue) if event.source.noteable.present? && event.source.noteable.is_a?(Issue)
    end
    ActiveRecord::Base.observers.disable :all
  end

  def down
    ActiveRecord::Base.observers.disable :all
    Event.where(action: [:commented_merge_request, :commented_issue]).find_each do |event|
      event.update_attribute(action: :commented_related)
    end
    ActiveRecord::Base.observers.disable :all
  end
end
