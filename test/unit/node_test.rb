require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class NodeTest < ActiveSupport::TestCase

  fixtures :nodes

  def test_fixtures_are_not_working
    begin
      nodes(:node_001).name
      assert false
    rescue StandardError
      assert true
    end
  end
  
end

