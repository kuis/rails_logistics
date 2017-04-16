class Users::PasswordsController < Devise::PasswordsController
  protected
  def after_resetting_password_path_for(resource)
    authenticated_root_path
  end
end
