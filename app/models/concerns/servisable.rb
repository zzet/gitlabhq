module Servisable
  extend ActiveSupport::Concern

  included do
    def to_param
      read_attribute(:id) || self.class.service_name(nil)
    end

    def title
      read_attribute(:title) || self.class.title
    end

    def description
      read_attribute(:description) || self.class.description
    end

    def service_name
      self.class.service_name
    end
  end

  module ClassMethods
    def default_title(attr)
      @title = attr
    end

    def title
      @title
    end

    def default_description(attr)
      @description = attr
    end

    def description
      @description
    end

    def service_name(attr)
      return @service_name if attr.nil?
      @service_name = attr
    end
  end
end
