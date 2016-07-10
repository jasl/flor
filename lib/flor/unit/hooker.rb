#--
# Copyright (c) 2015-2016, John Mettraux, jmettraux+flon@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

module Flor

  class Hooker

    # NB: logger configuration entries start with "hok_"

    def initialize(unit)

      @unit = unit

      @hooks = []
    end

    def shutdown

      @hooks.each do |n, o, hook, b|

        hook.shutdown if hook.respond_to?(:shutdown)
      end
    end

    def [](name)

      h = @hooks.find { |n, o, h, b| n == name }

      h ? h[2] || h[3] : nil
    end

    def add(*args, &block)

      name = nil
      hook = nil
      opts = {}

      args.each do |arg|
        case arg
          when String then name = arg
          when Hash then opts = arg
          else hook = arg
        end
      end

      hook = hook.new(@unit) if hook.is_a?(Class)

      @hooks << [ name, opts, hook, block ]
    end

    def notify(executor, message)

      @hooks.each do |n, opts, hook, block|

        next unless match?(message, opts)

        if hook
          hook.notify(executor, message)
        else # if block
          if block.arity == 1
            block.call(message)
          elsif block.arity == 2
            block.call(message, opts)
          else
            block.call(executor, message, opts)
          end
        end
      end
    end

    protected

    def o(opts, *keys)

      array = false
      array = keys.pop if keys.last == []

      r = nil
      keys.each { |k| break r = opts[k] if opts.has_key?(k) }

      return nil if r == nil
      array ? Array(r) : r
    end

    def match?(message, opts)

      c = o(opts, :consumed, :c)
      return false if c == true && ! message['consumed']
      return false if c == false && message['consumed']

      ps = o(opts, :point, :p, [])
      return false if ps && ! ps.include?(message['point'])

      if ds = o(opts, :domain, :d, [])
        exid = message['exid']
        return false \
          unless ds.find do |d|
            dl = d.length
            exid[0, dl] == d && %w[ - . ].include?(exid[dl, 1])
          end
      end

      if hps = o(opts, :heap, :hp, [])
        return false unless hps.include?(message['heap'])
      end

      if hts = o(opts, :heat, :ht, [])
        return false unless hts.include?(message['heat0'])
      end

      true
    end
  end
end
