class UserPolicy < ApplicationPolicy

  def index?
    @permission_attributes.map(&:action).include?('index') || @user.corporate?
  end

end
