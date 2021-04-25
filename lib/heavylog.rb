# frozen_string_literal: true

require "heavylog/version"
require "heavylog/formatters/raw"
require "heavylog/formatters/json"
require "heavylog/log_subscriber"
require "heavylog/middleware"
require "heavylog/ordered_options"
require "heavylog/request_logger"
require "heavylog/sidekiq_logger"
require "heavylog/sidekiq_exception_handler"

module Heavylog
  module_function

  TRUNCATION = "[TRUNCATED]"
  ANSI_REGEX = /\e\[(\d+)m/.freeze

  mattr_accessor :logger, :application, :formatter, :log_level

  def setup(app)
    self.application = app
    patch_loggers
    attach_to_action_controller
    attach_to_sidekiq
    setup_custom_payload
    set_options
  end

  def patch_loggers
    Rails.logger.extend(RequestLogger) if defined?(Rails)
  end

  def set_options
    if config.path
      f = File.open(config.path, "a")
      f.binmode
      f.sync = true

      Heavylog.logger = ActiveSupport::Logger.new(f)
    end

    Heavylog.formatter = config.formatter || Heavylog::Formatters::Raw.new
    Heavylog.log_level = config.log_level || :info
  end

  def attach_to_action_controller
    Heavylog::LogSubscriber.attach_to :action_controller
  end

  def attach_to_sidekiq
    return unless config.log_sidekiq

    Sidekiq.configure_server do |config|
      config.options[:job_logger] = SidekiqLogger
    end

    Sidekiq.error_handlers << SidekiqExceptionHandler.new
  end

  def setup_custom_payload
    return unless config.custom_payload_method.respond_to?(:call)

    klasses = Array(config.base_controller_class)
    klasses.map! { |klass| klass.try(:constantize) }
    klasses.push(ActionController::Base, ActionController::API) if klasses.empty?
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

  def log(_severity, message=nil, progname=nil)
    return unless config.enabled
    return if !!RequestStore.store[:heavylog_truncated]

    uuid = RequestStore.store[:heavylog_request_id]
    return unless uuid

    if message.nil?
      message =
        if block_given?
          yield
        else
          progname
        end
    end

    message = message.gsub(ANSI_REGEX, "") if message.respond_to?(:gsub)
    message = message.map { |m| m.respond_to?(:gsub) ? m.gsub(ANSI_REGEX, "") : m } if message.is_a?(Array)

    RequestStore.store[:heavylog_buffer] ||= StringIO.new

    if RequestStore.store[:heavylog_buffer].length + message_size(message) > config.message_limit
      RequestStore.store[:heavylog_buffer].truncate(0)
      RequestStore.store[:heavylog_buffer].puts(TRUNCATION)
      RequestStore.store[:heavylog_truncated] = true
    else
      RequestStore.store[:heavylog_buffer].puts(message)
    end
  end

  def log_sidekiq(jid, klass, args)
    return unless config.enabled

    RequestStore.store[:heavylog_request_id] = jid
    RequestStore.store[:heavylog_request_start] = Time.now.iso8601
    RequestStore.store[:heavylog_request_ip] = "127.0.0.1"

    RequestStore.store[:heavylog_request_data] = {
      controller: "SidekiqLogger",
      action:     klass,
      args:       args.to_s,
    }

    RequestStore.store[:heavylog_buffer] ||= StringIO.new
  end

  def finish
    return unless config.enabled

    buffer = RequestStore.store[:heavylog_buffer]
    return unless buffer && Heavylog.logger

    request = {
      request_id:    RequestStore.store[:heavylog_request_id],
      request_start: RequestStore.store[:heavylog_request_start],
      ip:            RequestStore.store[:heavylog_request_ip],
      messages:      buffer.string.dup,
    }.merge(RequestStore.store[:heavylog_request_data] || {})

    formatted = Heavylog.formatter.call(request)
    Heavylog.logger.send(Heavylog.log_level, formatted)
  rescue StandardError => e
    config.error_handler&.(e)
  end

  def finish_sidekiq
    finish
    RequestStore.store[:heavylog_buffer] = nil
  end

  def config
    return OrderedOptions.new unless application

    application.config.heavylog
  end

  def message_size(message)
    return message.bytesize if message.respond_to?(:bytesize)
    return message.map(&:to_s).sum(&:bytesize) if message.is_a?(Array)

    message.to_s.length
  end
end

require "heavylog/railtie" if defined?(Rails)
