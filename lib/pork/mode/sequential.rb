
module Pork
  module Sequential
    extend self

    def execute isolator, stat=Stat.new, paths=isolator.all_paths
      stat.prepare(paths)
      paths.inject(stat, &isolator.method(:isolate))
    end
  end
end
