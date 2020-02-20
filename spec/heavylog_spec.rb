# frozen_string_literal: true

RSpec.describe Heavylog do
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

  it "fetches message from block if block given" do
    Heavylog.log(nil) do
      "block message"
    end

    expect(RequestStore.store[:heavylog_buffer].string).to eq("block message\n")
  end

  it "fetches message from progname if message is nil" do
    Heavylog.log(nil, nil, "progname")

    expect(RequestStore.store[:heavylog_buffer].string).to eq("progname\n")
  end
end
