# frozen_string_literal: true

RSpec.describe Heavylog::Middleware do
  let(:buffer) { StringIO.new }
  let(:logger) { ActiveSupport::Logger.new(buffer) }
  let(:heavylog_config) do
    Heavylog::OrderedOptions.new.tap { |config|
      config.enabled = true
      config.message_limit = 1024 * 1024 * 50
      config.formatter = Heavylog::Formatters::Json.new
      config.custom_payload do |controller|
        user_id = controller.respond_to?(:current_user) ? controller.current_user&.id : nil

        {
          user_id: user_id,
        }
      end
    }
  end

  let(:app) { Rails.application }
  let(:request) { Rack::MockRequest.new(app) }

  before :each do
    RequestStore.clear!
    app.config.heavylog = heavylog_config
    Heavylog.setup(app)
    Heavylog.logger = logger
  end

  it "logs the request" do
    request.get("/test")

    expect(buffer.string).to include("logger from action")
  end
end
