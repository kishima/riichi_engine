require_relative "../spec_helper"
require_relative "python_mahjong_compat"

# Compares win evaluation with the Python package `mahjong` (PyPI). Needs a
# Python with the package; skipped without one. To set it up:
#
#   python3 -m venv .venv && .venv/bin/pip install mahjong
#
# (or point PYTHON_MAHJONG at a python that has it). For a larger run with a
# report: ruby spec/compat/run_python_mahjong.rb [COUNT] [SEED]
RSpec.describe "Python mahjong との突き合わせ" do
  before(:all) do
    skip "Python の mahjong パッケージが無い" unless PythonMahjongCompat.python
  end

  it "代表の形と乱数の形で、役・翻・符・点数が一致する（決まりの違いを除く）" do
    cases = PythonMahjongCompat.representative_cases + PythonMahjongCompat.random_cases(1000, seed: 1)
    results = PythonMahjongCompat.compare(cases)
    bad = results.reject { |r| r["diffs"].empty? }.map { |r| "#{r['case']['id']}: #{r['diffs'].join('; ')}" }

    expect(bad).to eq([])
    expect(results.count { |r| r["rule"] }).to be <= 2
  end
end
