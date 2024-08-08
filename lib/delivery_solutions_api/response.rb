# frozen_string_literal: true

module DeliverySolutionsAPI
  class Response
    ERROR_CODES = [
      500,
      400,
      404,
      409
    ].freeze

    def self.parse(payload:, status:)
      payload = case payload
                when String then JSON.parse(payload)
                when Hash then payload
                when Array then { collection: payload }
      end

      # NOTE: Handling case where payload is a String Array that got parsed
      payload = { collection: payload } if payload.is_a?(Array)

      new(payload:, status:)
    end

    attr_reader :payload, :status

    def initialize(status:, payload: {})
      @payload = Payload.new(payload)
      @status = status
    end

    def error?
      ERROR_CODES.include?(payload.statusCode)
    end

    def success?
      !error?
    end
  end
end
