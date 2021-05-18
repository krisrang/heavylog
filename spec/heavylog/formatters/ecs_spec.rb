# frozen_string_literal: true

RSpec.describe Heavylog::Formatters::ECS do
  let(:buffer) { StringIO.new }
  let(:logger) { ActiveSupport::Logger.new(buffer) }
  let(:heavylog_config) do
    Heavylog::OrderedOptions.new.tap { |config|
      config.enabled = true
      config.message_limit = 1024 * 1024 * 50
      config.formatter = subject
    }
  end

  subject { Heavylog::Formatters::ECS.new }
  let(:app) { Rails.application }
  let(:request) { Rack::MockRequest.new(app) }

  before :each do
    app.config.heavylog = heavylog_config
    Heavylog.set_options
    Heavylog.logger = logger
  end

  it "logs the request as JSON using ECS fields" do
    request.get("/test")

    line = JSON.parse(buffer.string)

    expect(line["message"]).to include("logger from action")
  end

  it "assigns ECS fields deeply as a nested hash" do
    request.get("/test", { "HTTP_REFERER" => "stackoverflow.com" })

    line = JSON.parse(buffer.string)

    expect(line.dig("event", "module")).to eq("heavylog")
  end
end
