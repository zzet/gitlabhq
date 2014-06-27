module SummariesHelper
  def source_actions(target, source)
    target.class.result_actions_names(source)
  end
end
