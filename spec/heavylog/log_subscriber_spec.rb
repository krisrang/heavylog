# frozen_string_literal: true

RSpec.describe Heavylog::LogSubscriber do
  let(:buffer) { StringIO.new }
  let(:logger) { ActiveSupport::Logger.new(buffer) }
  let(:heavylog_config) do
    Heavylog::OrderedOptions.new.tap { |config|
      config.enabled = true
      config.message_limit = 1024 * 1024 * 50
      config.formatter = Heavylog::Formatters::Json.new
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

  it "logs redirects" do
    request.get("/redirect")

    expect(JSON.parse(buffer.string)["location"]).to eq("http://redirected.com")
  end
end
