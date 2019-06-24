# frozen_string_literal: true

RSpec.describe Heavylog do
  let(:app_config) do
    double(config: ActiveSupport::OrderedOptions.new.tap { |config|
                     config.heavylog = ActiveSupport::OrderedOptions.new
                     config.heavylog.enabled = true
                     config.heavylog.message_limit = 1024 * 1024 * 50
                   })
  end

  before :each do
    RequestStore.clear!
    Heavylog.setup(app_config)
    RequestStore.store[:heavylog_request_id] = SecureRandom.hex
  end

  it "has a version number" do
    expect(Heavylog::VERSION).not_to be nil
  end

  it "filters ansi from messages" do
    message = "\u001b[1m\u001b[35m (0.8ms)\u001b[0m  \u001b[1m\u001b[35mCOMMIT\u001b[0m"

    Heavylog.log(nil, message)

    expect(RequestStore.store[:heavylog_buffer].string).to eq(" (0.8ms)  COMMIT\n")
  end

  it "only tries to filter ansi from messages when possible" do
    message = ["\u001b[1m\u001b[35m (0.8ms)\u001b[0m  \u001b[1m\u001b[35mCOMMIT\u001b[0m"]

    Heavylog.log(nil, message)

    expect(RequestStore.store[:heavylog_buffer].string).to eq(" (0.8ms)  COMMIT\n")
  end
end
