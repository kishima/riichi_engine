require_relative "../spec_helper"

RSpec.describe RiichiEngine do
  it "Zeitwerk の eager_load ですべてのファイルを読み込める" do
    expect { described_class.loader.eager_load }.not_to raise_error
    expect(RiichiEngine::API).to be_a(Module)
    expect(RiichiEngine::VERSION).to be_a(String)
  end
end
