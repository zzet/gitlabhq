class Profiles::Summaries::ApplicationController < Profiles::ApplicationController

  def summary
    @summary ||= Event::Summary.find(params[:summary_id])
  end

  def extract_options(klass, params)
    options = {}
    param = params[:event_summary_entity_relationship]
    opts = begin
             param[:options].keep_if do |option|
               klass.watched_sources.include?(option.to_sym)
             end
           rescue
             []
           end

    opts.each do |option|
      actions = begin
                  param[:"options_#{option}_actions"].keep_if do |action|
                    klass.result_actions_names(option.to_sym).include?(action.to_sym)
                  end
                rescue
                  []
                end

      if actions.any?
        options[option] = actions.inject({}) {|r, a| r.merge!({ a => true })}

        if klass.is_a?(Project)
          if option == "push" && actions.include?("pushed")
            branshes = [params[:"options_#{option}_actions_pushed_branches"]].flatten
            branshes.delete!("Any branch")
            if branshes.any?
              options["push"]["pushed"] = branshes
            end
          end
        end
      else
        opts.delete!(option)
      end
    end

    options.deep_symbolize_keys!

    return opts, options
  end
end
