# Prints the comparison of riichi_engine with the Python `mahjong` package:
#   ruby spec/compat/run_python_mahjong.rb [COUNT] [SEED]
# (COUNT random hands, 2000 by default, plus the representative hands).
require_relative "../../lib/riichi_engine"
require_relative "python_mahjong_compat"

abort "Python with the mahjong package not found (see spec/compat/python_mahjong_spec.rb)" unless PythonMahjongCompat.python

count = (ARGV[0] || 2000).to_i
seed = (ARGV[1] || 1).to_i
cases = PythonMahjongCompat.representative_cases + PythonMahjongCompat.random_cases(count, seed:)
results = PythonMahjongCompat.compare(cases)
bad = results.reject { |r| r["diffs"].empty? }
rules = results.select { |r| r["rule"] }
no_yaku = results.count { |r| r["engine"]["error"] && r["python"]["error"] }
puts "mahjong #{PythonMahjongCompat.python_version}: #{cases.size} hands " \
     "(#{cases.size - count} representative, #{count} random, seed #{seed}): " \
     "#{no_yaku} without yaku in both, #{bad.size} differ, #{rules.size} differ by rule"
rules.group_by { |r| r["rule"] }.each { |rule, rs| puts "  rule: #{rule}: #{rs.map { |r| r['case']['id'] }.join(' ')}" }
summary = Hash.new(0)
bad.each { |r| r["diffs"].each { |d| summary[d.sub(/:.*/, "")] += 1 } }
summary.sort_by { -_2 }.each { |k, n| puts "  #{k}: #{n}" }
bad.first(ENV.fetch("SHOW", 40).to_i).each do |r|
  c = r["case"]
  puts "- #{c['id']}: #{c['concealed'].join(' ')} win #{c['win']} #{c['tsumo'] ? 'tsumo' : 'ron'} " \
       "melds #{c['melds'].map { |m| "#{m['type']}:#{m['tiles'].join}" }.join(' ')} " \
       "#{%w[riichi ippatsu double_riichi haitei houtei rinshan chankan tenhou chiihou].select { c[_1] }.join(',')} " \
       "#{c['bakaze']}/#{c['jikaze']} dora #{c['dora_hyouji'].join} ura #{c['uradora_hyouji'].join}"
  r["diffs"].each { |d| puts "    #{d}" }
end
