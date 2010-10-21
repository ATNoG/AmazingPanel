module TestbedsHelper
  def testbed_user_path(testbed, user)
    "/testbeds/#{testbed.id}/user/#{user.id}"
  end

  def testbed_leader_path(testbed, user)
    "/testbeds/#{testbed.id}/user/#{user.id}/leader"
  end
  
  def testbed_is_user_assigned?(testbed, id)
     return (testbed.user_ids.index(id).nil?)
  end  
  
  def testbed_users_empty?(testbed)
     return testbed.user_ids.empty?
  end

  def is_user_leader(testbed, user)
     @user = Testbed.find(testbed.id).users.find(user.id)
     return (@user.leader == 't')
  end
end
