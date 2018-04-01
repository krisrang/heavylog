# frozen_string_literal: true
require 'heavylog/version'
require 'heavylog/formatters/raw'
require 'heavylog/formatters/json'
require 'heavylog/log_subscriber'
require 'heavylog/middleware'
require 'heavylog/ordered_options'
require 'heavylog/request_logger'

module Heavylog
  module_function

  mattr_accessor :logger, :application, :formatter, :log_level

  def setup(app)
    self.application = app
    patch_loggers
    attach_to_action_controller
    setup_custom_payload
    set_options
  end

  def patch_loggers
    Rails.logger.extend(RequestLogger)
  end

  def set_options
    f = File.open(config.path, 'a')
    f.binmode
    f.sync = true

    Heavylog.logger = ActiveSupport::Logger.new(f)
    Heavylog.formatter = config.formatter || Heavylog::Formatters::Raw.new
    Heavylog.log_level = config.log_level || :info
  end

  def attach_to_action_controller
    Heavylog::LogSubscriber.attach_to :action_controller
  end

  def setup_custom_payload
    return unless config.custom_payload_method.respond_to?(:call)

    klasses = Array(config.base_controller_class)
    klasses.map! { |klass| klass.try(:constantize) }
    klasses.push(ActionController::Base) if klasses.empty?
    klasses.each { |klass| extend_base_controller_class(klass) }
  end

  def extend_base_controller_class(klass)
    append_payload_method = klass.instance_method(:append_info_to_payload)
    custom_payload_method = config.custom_payload_method

    klass.send(:define_method, :append_info_to_payload) do |payload|
      append_payload_method.bind(self).call(payload)
      payload[:custom_payload] = custom_payload_method.call(self)
    end
  end

  def log(severity, message = nil, progname = nil, &block)
    return if !config.enabled

    uuid = RequestStore.store[:heavylog_request_id]
    return if !uuid

    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
      end
    end

    RequestStore.store[:heavylog_buffer] ||= StringIO.new
    RequestStore.store[:heavylog_buffer].puts(message)
  end

  def finish
    return if !config.enabled

    buffer = RequestStore.store[:heavylog_buffer]
    return if !buffer

    request = {
      request_id: RequestStore.store[:heavylog_request_id],
      messages: buffer.string.dup
    }.merge(RequestStore.store[:heavylog_request_data] || {})

    formatted = Heavylog.formatter.call(request)
    Heavylog.logger.send(Heavylog.log_level, formatted)
  end

  def config
    application.config.heavylog
  end
end

require 'heavylog/railtie' if defined?(Rails)
