class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    # in Ability#initialize
    unless user.nil? 
      if user.is? :experimenter        
        # user
        can [:read, :update], User, { :id => user.id }

        # projects
        can :create, Project
        can [:users, :read, :index], Project do |p|
          !p.private? || ProjectsUsers.where({:project_id => p.id, :user_id => user.id}).length > 0
        end      
      
        # leader
        can [:edit, :unassign_user, :assign_user, :assign, :make_leader, :update, :destroy], Project do |p|
          ProjectsUsers.where(:project_id => p.id, :user_id => user.id, :leader => 1).length == 1
        end
        
        # experiment
        can [:queue, :create], Experiment
        can [:read, :update, :destroy, :prepare, :run, :start, :stop, :stat], Experiment do |e|
          e.user_id == user.id || ProjectsUsers.where({:project_id => e.project_id, :user_id => user.id}).length > 0
        end      
        
        # manage his own eds
        can [:read, :create], Ed
        can [:update, :destroy, :edit], Ed, { :user_id => user.id }
  
        # manage his own sys images
        can [:read, :create], SysImage
        can [:update, :destroy, :edit], SysImage, { :user_id => user.id }
        
        # can see nodes info and state
        can [:read, :node_info], Testbed
      end
      if user.is? :maintainer        
        can :manage, Testbed
      end
      if user.is? :moderator
        can :manage, Ed
        can :manage, SysImage
        can :manage, Experiment
        can :manage, Project, :private => false
      end
      can :manage, :all if user.admin?
    end
  end
end
