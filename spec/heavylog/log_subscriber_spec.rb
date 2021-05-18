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
    app.config.heavylog = heavylog_config
    Heavylog.set_options
    Heavylog.logger = logger
  end

  it "logs redirects" do
    request.get("/redirect")

    expect(JSON.parse(buffer.string)["location"]).to eq("http://redirected.com")
  end

  it "logs exceptions" do
    request.get("/raise")

    line = JSON.parse(buffer.string)

    expect(line["status"]).to eq(500)
    expect(line["error"]).to include("This action raises an exception")
  end

  describe "referrer" do
    it "logged when it exists" do
      request.get("/test", { "HTTP_REFERER" => "stackoverflow.com" })

      line = JSON.parse(buffer.string)

      expect(line["referrer"]).to eq("stackoverflow.com")
    end

    it "is ignored when it doesn't exist" do
      request.get("/test")

      line = JSON.parse(buffer.string)

      expect(line.key?("referrer")).to eq(false)
    end
  end
end
