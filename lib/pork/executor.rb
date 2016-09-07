
require 'pork/runner'
require 'pork/context'

module Pork
  class Executor < Struct.new(:pork_stat, :pork_description)
    module Imp
      attr_reader :desc, :tests

      def before &block; @tests << [:before, block]; end
      def after  &block; @tests << [:after , block]; end

      def copy  desc=:default, &suite
        @stash[desc] = suite
      end
      def paste desc=:default, *args
        module_exec(*args, &search_stash(desc))
      end

      def describe desc=:default, opts={}, &suite
        executor = Class.new(self){ init(desc) }
        executor.module_eval(&suite)
        @tests << [:describe, executor, suite, opts]
      end

      def would desc=:default, opts={}, &test
        raise ArgumentError.new("no block given") unless test
        @tests << [:would   , desc    , test, opts]
      end

      def description_for name=''
        if @super_executor
          "#{@super_executor.description_for}#{@desc}: #{name}"
        else
          name
        end
      end

      def run *args
        Runner.new(self, Pork.reseed, *args).run
      end

      private
      def init desc=''
        @desc, @tests, @stash = desc, [], {}
        @super_executor = ancestors[1..-1].find{ |a| a <= Executor }
      end

      protected
      def search_stash desc
        @stash[desc] or @super_executor && @super_executor.search_stash(desc)
      end
    end

    extend Imp
    include Context
    init
  end
end
