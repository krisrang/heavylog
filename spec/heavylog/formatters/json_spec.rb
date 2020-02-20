# frozen_string_literal: true

RSpec.describe Heavylog::Formatters::Json do
  let(:buffer) { StringIO.new }
  let(:logger) { ActiveSupport::Logger.new(buffer) }
  let(:heavylog_config) do
    Heavylog::OrderedOptions.new.tap { |config|
      config.enabled = true
      config.message_limit = 1024 * 1024 * 50
      config.formatter = subject
    }
  end

  subject { Heavylog::Formatters::Json.new }
  let(:app) { Rails.application }
  let(:request) { Rack::MockRequest.new(app) }

  before :each do
    RequestStore.clear!
    app.config.heavylog = heavylog_config
    Heavylog.setup(app)
    Heavylog.logger = logger
  end

  it "logs the request as JSON" do
    request.get("/test")

    line = JSON.parse(buffer.string)

    expect(line["messages"]).to include("logger from action")
  end
end
