
require 'pork/executor'

module Pork
  module API
    module_function
    def before &block; Executor.before(&block); end
    def after  &block; Executor.after( &block); end
    def copy     desc=:default, &block; Executor.copy(    desc, &block); end
    def paste    desc=:default, *args ; Executor.paste(   desc, *args ); end
    def describe desc=:default, &suite; Executor.describe(desc, &suite); end
    def would    desc=:default, &test ; Executor.would(   desc, &test ); end
  end

  # default to :shuffled while eliminating warnings for uninitialized ivar
  def self.execute_mode execute=nil
    @execute = execute || @execute ||= :shuffled
  end

  def self.Rainbows!
    require 'pork/extra/rainbows'
    Pork::Stat.__send__(:include, Pork::Rainbows)
  end

  def self.show_source
    require 'pork/extra/show_source'
    Pork::Stat.__send__(:include, Pork::ShowSource)
  end

  def self.stat
    @stat ||= Pork::Stat.new
  end

  def self.seed
    @seed ||= if Random.const_defined?(:DEFAULT)
                Random::DEFAULT.seed
              else
                Thread.current.randomizer.seed # Rubinius (rbx)
              end
  end

  def self.trap sig='SIGINT'
    Signal.trap(sig) do
      stat.report
      puts "\nterminated by signal #{sig}"
      exit 255
    end
  end

  def self.run
    Random.srand(ENV['PORK_SEED'].to_i) if ENV['PORK_SEED']
    seed
    if ENV['PORK_TEST']
      require 'pork/mode/shuffled'
      if paths = Executor[ENV['PORK_TEST']]
        @stat = Executor.execute(Pork.execute_mode, stat, paths)
      else
        puts "Cannot find test: #{ENV['PORK_TEST']}"
        exit 254
      end
    else
      @stat = Executor.execute(Pork.execute_mode, stat)
    end
  end

  def self.autorun auto=true
    @auto = auto
    @autorun ||= at_exit do
      next unless @auto
      execute_mode(ENV['PORK_MODE'])
      trap
      run
      stat.report
      exit stat.failures + stat.errors + ($! && 1).to_i
    end
  end
end
