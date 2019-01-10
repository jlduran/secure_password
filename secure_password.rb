# frozen_string_literal: true

module ActiveModel
  module SecurePassword
    extend ActiveSupport::Concern

    class << self
      attr_accessor :min_cost # :nodoc:
    end
    self.min_cost = false

    module ClassMethods
      # Adds methods to set and authenticate against an SCrypt password.
      # This mechanism requires you to have a +XXX_digest+ attribute.
      # Where +XXX+ is the attribute name of your desired password.
      #
      # The following validations are added automatically:
      # * Password must be present on creation
      # * Password length should be less than or equal to 72 bytes
      # * Confirmation of password (using a +XXX_confirmation+ attribute)
      #
      # If confirmation validation is not needed, simply leave out the
      # value for +XXX_confirmation+ (i.e. don't provide a form field for
      # it). When this attribute has a +nil+ value, the validation will not be
      # triggered.
      #
      # For further customizability, it is possible to suppress the default
      # validations by passing <tt>validations: false</tt> as an argument.
      #
      # Add scrypt (~> 3.0.6) to Gemfile to use #has_secure_password:
      #
      #   gem 'scrypt', '~> 3.0.6'
      #
      # Example using Active Record (which automatically includes ActiveModel::SecurePassword):
      #
      #   # Schema: User(name:string, password_digest:string, recovery_password_digest:string)
      #   class User < ActiveRecord::Base
      #     has_secure_password
      #     has_secure_password :recovery_password, validations: false
      #   end
      #
      #   user = User.new(name: 'david', password: '', password_confirmation: 'nomatch')
      #   user.save                                                       # => false, password required
      #   user.password = 'mUc3m00RsqyRe'
      #   user.save                                                       # => false, confirmation doesn't match
      #   user.password_confirmation = 'mUc3m00RsqyRe'
      #   user.save                                                       # => true
      #   user.recovery_password = "42password"
      #   user.recovery_password_digest                                   # => "4000$8$1$831f1796d19afaa5efcd40d0fec9cf6516730bca78b168fc9f20809c202604e2$af2d2e383d22b5fb38aaddfa2c7b9b1280631cb864287bffd36f4c6e62f102c8"
      #   user.save                                                       # => true
      #   user.authenticate('notright')                                   # => false
      #   user.authenticate('mUc3m00RsqyRe')                              # => user
      #   user.authenticate_recovery_password('42password')               # => user
      #   User.find_by(name: 'david').try(:authenticate, 'notright')      # => false
      #   User.find_by(name: 'david').try(:authenticate, 'mUc3m00RsqyRe') # => user
      def has_secure_password(attribute = :password, validations: true)
        # Load scrypt gem only when has_secure_password is used.
        # This is to avoid ActiveModel (and by extension the entire framework)
        # being dependent on a binary library.
        begin
          require "scrypt"
        rescue LoadError
          $stderr.puts "You don't have scrypt installed in your application. Please add it to your Gemfile and run bundle install"
          raise
        end

        attr_reader attribute

        define_method("#{attribute}=") do |unencrypted_password|
          if unencrypted_password.nil?
            self.send("#{attribute}_digest=", nil)
          elsif !unencrypted_password.empty?
            instance_variable_set("@#{attribute}", unencrypted_password)
            cost = ActiveModel::SecurePassword.min_cost ? nil : SCrypt::Engine::DEFAULTS[:cost]
            self.send("#{attribute}_digest=", SCrypt::Password.create(unencrypted_password, cost: cost))
          end
        end

        define_method("#{attribute}_confirmation=") do |unencrypted_password|
          instance_variable_set("@#{attribute}_confirmation", unencrypted_password)
        end

        # Returns +self+ if the password is correct, otherwise +false+.
        #
        #   class User < ActiveRecord::Base
        #     has_secure_password validations: false
        #   end
        #
        #   user = User.new(name: 'david', password: 'mUc3m00RsqyRe')
        #   user.save
        #   user.authenticate_password('notright')      # => false
        #   user.authenticate_password('mUc3m00RsqyRe') # => user
        define_method("authenticate_#{attribute}") do |unencrypted_password|
          attribute_digest = send("#{attribute}_digest")
          SCrypt::Password.new(attribute_digest).is_password?(unencrypted_password) && self
        end

        alias_method :authenticate, :authenticate_password if attribute == :password

        if validations
          include ActiveModel::Validations

          # This ensures the model has a password by checking whether the password_digest
          # is present, so that this works with both new and existing records. However,
          # when there is an error, the message is added to the password attribute instead
          # so that the error message will make sense to the end-user.
          validate do |record|
            record.errors.add(attribute, :blank) unless record.send("#{attribute}_digest").present?
          end

          validates_confirmation_of attribute, allow_blank: true
        end
      end
    end
  end
end
