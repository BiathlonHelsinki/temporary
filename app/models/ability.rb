class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new 
    if user.has_role? :admin
      can :manage, :all
      can :manage, Page
      can :manage, Post
      can :manage, Credit
      can :manage, Email
    else
      can :read, :all
      can :manage, User, :id => user.id
      cannot :manage, Post
      cannot :manage, Credit
      cannot :manage, Page
      cannot :manage, Email
      
    end
  end
end
