class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new 
    if user.has_role? :admin
      can :manage, :all
      can :manage, Page
      can :manage, Post
    else
      can :read, :all
      can :manage, User, :id => user.id
    end
  end
end
