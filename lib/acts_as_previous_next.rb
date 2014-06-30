require 'active_support/concern'

module ActsAsPreviousNext
  extend ActiveSupport::Concern

  included do
    def self.acts_as_previous_next(options = {})
      configuration = { column: 'id', with_cancan: false,condition_columns: nil }
      configuration.update(options) if options.is_a?(Hash)

      if options.is_a? Symbol
        column = options.to_s
        with_cancan = false
      elsif options.is_a? Hash
        column      = options[:column] || "id"
        condition_columns = options[:condition_columns]
        with_cancan = options[:with_cancan]
      end

      class_eval <<-EOF
        if with_cancan
          def next(ability)
            self.class.accessible_by(ability).where("#{column} > ?", self.send('#{column}')).order("#{column}").first ||
            self.class.accessible_by(ability).order("#{column}").first
          end

          def previous(ability)
            self.class.accessible_by(ability).where("#{column} < ?", self.send('#{column}')).order("#{column} DESC").first ||
            self.class.accessible_by(ability).order("#{column} DESC").first
          end
        else
          def next
            self.class.where("#{column} > ?", self.send('#{column}')).order("#{column}").first ||
            self.class.order("#{column}").first
          end

          def previous
            self.class.where("#{column} < ?", self.send('#{column}')).order("#{column} DESC").first ||
            self.class.order("#{column} DESC").first
          end
        end
        def compose_condition
          return "" if condition_columns.blank?
          return "#{condition_columns}=#{self.send(condition_columns)}" if condition_columns.is_a? String
          return (condition_columns.map{|c|"#{c}=#{self.send(c)}"}).join(" and ") if condition_columns.is_a? Array           
        end
      EOF
    end
  end
end

ActiveRecord::Base.send :include, ActsAsPreviousNext
