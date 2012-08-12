require 'active_record'

module Preferences
  class Preference < ActiveRecord::Base
    belongs_to :holder, :polymorphic => true
    validates_uniqueness_of :key, :scope => [:holder_type, :holder_id]
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def has_preferences(options = {})
      configuration = { :proxy => nil }
      configuration.update(options) if options.is_a?(Hash)
      define_method :preferences_parent do
        if configuration[:parent].nil?
          nil
        else
          configuration[:parent]
        end
      end
      include InstanceMethods
      has_many :preferences, :as => :holder, :class_name => Preferences::Preference
    end
  end

  module InstanceMethods
    def pref(*args)
      key = args[0].to_s
      if args.size == 1
        return get_pref(key)
      elsif args.size == 2
        value = args[1].to_s
        return set_pref(key, value)
      end
    end

    private
    def get_pref(key)
      preference = Preference.where(pref_opts(key)).first
      unless preference.nil?
        value = preference.value
      end
      if value.nil?
        if preferences_parent.nil?
          parent = nil
        else 
          parent = self.send(preferences_parent)
        end
        unless parent.nil?
          value = parent.pref(key)
        end
      end
      value
    end

    def set_pref(key, value)
      preference = Preference.where(pref_opts(key)).first || Preference.create(pref_opts(key))
      if preference.value != value 
        preference.value = value
        preference.save
      end
      value
    end

    def pref_opts(key)
      {:key => key, 
       :holder_type => self.class.to_s, 
       :holder_id => self.id.to_s}
    end

    def pref_cache_key(key)
      pref_opts(key).values.join(':')
    end
  end
end

ActiveRecord::Base.send :include, Preferences
