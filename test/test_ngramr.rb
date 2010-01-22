require 'helper'

class TestNgramr < Test::Unit::TestCase
  should "" do
    y = {}
    s = NGramSearcher.new(:dir => 'search_index', :size => 3, :min => 1)
    s.wrap(y)
    y['foo'] = 'abcd京都def'
    y['bar'] = 'defghi東京都'
    y['baz'] = 'bccdde'
    results = ['abc', 'def', 'ghi', '京都', '東京', '奈良', 'bcde',
        '京'].map do |q|
      [s.search(q).join(', '),  s.search(q, true).join(', ')]
    end
    assert_equal results, [
        ["foo", "foo"],
        ["foo, bar", "foo, bar"],
        ["bar", "bar"],
        ["foo, bar", "foo, bar"],
        ["bar", "bar"],
        ["", ""],
        ["", "foo, baz"],
        ["foo, bar", "foo, bar"],
        ]
  end
end
