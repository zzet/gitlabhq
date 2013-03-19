class Gitlab::Event::Builder::Base

  class << self
    def descendants
      # In production class cache :)
      Dir[File.dirname(__FILE__) << "/**/*.rb"].each {|f| load f} if super.blank?

      super
    end

    def can_build?(action, data)
      raise NotImplementedError
    end

    def build(action, target, user, data)
      raise NotImplementedError
    end

    def known_action?(action, available_actions)
      meta = parse_action(action)
      available_actions.include? meta[:action]
    end

    def known_source?(source, known_sources)
      source_sym = source.watchable_name

      known_sources.include? source_sym
    end

    private

    def parse_action(action)
      info = action.split "."
      info.shift # Shift "gitlab"
      {
        action: info.shift.to_sym,
        details: info
      }
    end
  end
end
