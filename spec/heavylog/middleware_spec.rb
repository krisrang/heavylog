# frozen_string_literal: true

RSpec.describe Heavylog::Middleware do
  let(:buffer) { StringIO.new }
  let(:logger) { ActiveSupport::Logger.new(buffer) }

  let(:app) { Rails.application }
  let(:request) { Rack::MockRequest.new(app) }

  before :each do
    Heavylog.logger = logger
    Heavylog.ignore_path = nil
  end

  it "logs the request" do
    request.get("/test")

    expect(buffer.string).to include("logger from action")
  end

  it "ignores the request" do
    Heavylog.ignore_path = %r{/ignore|/otherignore}
    request.get("/ignore")
    expect(buffer.string).to eq("")

    Heavylog.ignore_path = nil
    request.get("/ignore")
    expect(buffer.string).to include("logger from action")
  end
end
