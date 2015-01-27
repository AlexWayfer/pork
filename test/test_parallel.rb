
require 'pork/test'
require 'pork/mode/parallel'

describe Pork::Parallel do
  paste

  would '#parallel' do
    stat = Pork::Executor.parallel(pork_stat)
    expect(stat.passed?, stat.inspect).eq true
  end
end
