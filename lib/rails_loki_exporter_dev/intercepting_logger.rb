# frozen_string_literal: true

require 'json'
require 'net/http'
require 'active_support/logger'

module RailsLokiExporterDev
  class InterceptingLogger < ActiveSupport::Logger
    attr_accessor :client

    SEVERITY_NAMES = %w(DEBUG INFO WARN ERROR FATAL).freeze

    def initialize(intercept_logs: false)
      @intercept_logs = intercept_logs
      @log = ""
      super(STDOUT)
      self.level = Logger::DEBUG
    end

    def add(severity, message = nil, progname = nil, &block)
      severity_name = severity_name(severity)
      log_message = message
      if log_message.nil?
        if block_given?
          log_message = yield
        end
      end

      @log = format_message(severity_name, Time.now, progname, log_message)
      if @intercept_logs
        if log_message.nil?
          puts caller
        else
          client.send_log("#{log_message}") if client
        end
      end
      super(severity, message, progname, &block)
    end

    def debug(log_message)
      client.send_log("#{log_message}") if client
    end

    def broadcast_to(console)
      client.send_log(@log) if client
    end

    private

    def format_message(severity, datetime, progname, msg)
      "#{severity} #{progname}: #{msg}\n"
    end

    def severity_name(severity)
      SEVERITY_NAMES[severity] || "UNKNOWN"
    end
  end
end