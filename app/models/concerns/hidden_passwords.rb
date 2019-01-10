# frozen_string_literal: true

module HiddenPasswords
  extend ActiveSupport::Concern

  def serializable_hash(options = {})
    super options.merge(except: 'password_digest')
  end

  def inspect
    inspection = serializable_hash.collect do |k, v|
      "#{k}: #{respond_to?(:attribute_for_inspect) ? attribute_for_inspect(k) : v.inspect}"
    end

    "#<#{self.class} #{inspection.join(', ')}>"
  end
end
