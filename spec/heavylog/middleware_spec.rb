# frozen_string_literal: true

RSpec.describe Heavylog::Middleware do
  let(:buffer) { StringIO.new }
  let(:logger) { ActiveSupport::Logger.new(buffer) }

  let(:app) { Rails.application }
  let(:request) { Rack::MockRequest.new(app) }

  before :each do
    Heavylog.logger = logger
  end

  it "logs the request" do
    request.get("/test")

    expect(buffer.string).to include("logger from action")
  end
end
