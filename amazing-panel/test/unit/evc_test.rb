require 'test_helper'
require 'evc'

class EVCTest < ActiveSupport::TestCase

  test "new branch" do
    b = EVC::Branch.new('exp1', 'user1')
    result = b.new_branch('long description')
    puts result
  end

  test "commit branch" do
    b = EVC::Branch.new('exp1', 'user2')
    b.commit_branch('long description, or not!', 'code here', {'resource_map' => 'here'})
  end


  test "save run" do
    b = EVC::Branch.new('exp1', 'user2')
    b.save_run(0, ["/tmp/evc.log", "/tmp/evc-state.xml", "/tmp/evc-prepare.xml"])
  end
end
