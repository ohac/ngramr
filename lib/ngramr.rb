#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'base64'

class NGramSearcher

  attr_accessor :dir, :size, :kvs, :min

  def initialize(opts)
    self.dir = opts[:dir]
    Dir.mkdir(dir) unless File.exist?(dir)
    self.size = opts[:size] || 2
    self.min = opts[:min] || 2
  end

  def []=(key, value)
    (min..size).each do |n|
      ngram_func(value, n) do |a|
        File.open(ngram_path(a), 'a') { |f| f.puts(key) }
      end
    end
  end

  def makeindex
    kvs.each do |k,v|
      self[k] = v
    end
  end

  def search(q, lazy = false)
    keychain = nil
    (min..size).to_a.reverse.each do |n|
      paths = []
      ngram_func(q, n) do |a|
        paths << ngram_path(a)
      end
      next if paths.size == 0
      keychains = paths.uniq.map do |path|
        next [] unless File.exist?(path)
        File.open(path) { |f| f.readlines.uniq.map(&:chomp) }
      end
      keychain = keychains.reduce { |x, y| x & y }
      break if keychain.size > 0
    end
    return [] if keychain.nil?
    return keychain if lazy or kvs.nil?
    keychain.select do |key|
      !kvs[key].index(q).nil?
    end
  end

  def wrap(kvs)
    kvs.class.class_eval do
      def set_searcher(searcher)
        @searcher = searcher
      end
      def update_with_searcher(key, value)
        @searcher[key] = value
        original_update(key, value)
      end
      alias_method :original_update, :"[]="
      alias_method :"[]=", :update_with_searcher
    end
    kvs.set_searcher(self)
    self.kvs = kvs
  end

  def ngram_func(text, n)
    text.split(//u).each_cons(n).map(&:join).uniq.each do |a|
      yield a
    end
  end

  def ngram_path(a)
    path = Base64.encode64(a).chomp
    path.gsub!(/([A-Z+\/])/, '.\1')
    path.downcase!
    path.tr!('+/', '%-')
    File.join(dir, path)
  end

end
