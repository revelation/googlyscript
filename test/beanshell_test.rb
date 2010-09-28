require 'test_helper'

class BeanShellTest < Test::Unit::TestCase
  
  BEANSHELL = Googly::BeanShell.new
  
  def test_basic_run
    assert_equal "pass\n", BEANSHELL.run('print("pass");')
  end

end
