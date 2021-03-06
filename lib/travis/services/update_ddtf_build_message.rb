require 'active_support/core_ext/hash/except'
require 'travis/support/instrumentation'
require 'travis/services/base'
require 'date'

module Travis
  module Services
    class UpdateDdtfBuildMessage < Base
      extend Travis::Instrumentation

      register :update_ddtf_build_message

      EVENT = [:message]

      def run
        integer_test = Integer(data[:position]) rescue nil
        return unless integer_test

        datetime_test = DateTime.parse(data[:timestamp]) rescue nil
        return unless datetime_test

        execution_log = ExecutionLog.new ({
          position: data[:position],
          message: data[:message],
          timestamp: data[:timestamp], 
        })

        execution_log.build_id = data[:id]

        execution_log.save!
      end

      instrument :run

      def build
        @build ||= run_service(:find_build, data)
      end

      def data
        @data ||= begin
          params[:data].symbolize_keys
        end
      end

      def event
        @event ||= EVENT.detect { |event| event == params[:event].try(:to_sym) } || raise_unknown_event
      end

      def raise_unknown_event
        raise ArgumentError, "Unknown event: #{params[:event]}, data: #{data}"
      end

      class Instrument < Notification::Instrument
        def run_completed
          publish(
            msg: "event: #{target.event} for <Build id=#{target.data[:id]}> data=#{target.data.inspect}",
            build_id: target.data[:id],
            event: target.event,
            data: target.data
          )
        end
      end
      Instrument.attach_to(self)
    end
  end
end
