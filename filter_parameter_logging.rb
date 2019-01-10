# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]

# XXX: This should be baked-in somewhow
module ActiveRecord
  class LogSubscriber < ActiveSupport::LogSubscriber
    def render_bind(attr, value)
      if attr.is_a?(Array)
        attr = attr.first
      elsif attr.type.binary? && attr.value
        value = "<#{attr.value_for_database.to_s.bytesize} bytes of binary data>"
      end

      # XXX: Use require "active_support/parameter_filter"
      if attr.name == 'password_digest'
        value = '[FILTERED]'
      end

      [attr && attr.name, value]
    end
  end
end
