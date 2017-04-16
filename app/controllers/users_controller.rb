class UsersController < ApplicationController
  add_breadcrumb I18n.t("controllers.users.team"), :users_path, :options => { :title => I18n.t("controllers.users.team") }
  before_filter :authenticate_user!
  respond_to :html, :json
  load_and_authorize_resource
  load_and_authorize_resource skip_load_resource only: [:create]

  def user_params
    if can? :manage_restricted_attributes, User
      params.require(:user).permit :name, :title, :email, :phone_number, :password, :password_confirmation, :avatar, :remove_avatar,
        :current_property_role_id, current_property_user_role_attributes: [:id, :role_id, :title, :order_approval_limit], department_ids: [], settings: [:work_order_group_by, :primary_hotel]
    else
      params.require(:user).permit( :name, :title, :email, :phone_number, :password, :password_confirmation, :avatar, :remove_avatar, settings: [:work_order_group_by, :primary_hotel] )
    end
  end
  private :user_params

  def index
    authorize User
    target = current_user.corporate? ? current_user.corporate : Property.current
    @scope = params[:scope]
    if @scope == 'deleted'
      @user_roles = target.user_roles.only_deleted.order(:deleted_at)
    else
      @matching_users = target.users.active
      # @matching_users += current_property.corporate.users if current_property.corporate.present?
      @pending_invitations = target.join_invitations
    end

    respond_with @matching_users
  end

  def new
    @user = User.new
    @user.current_property_user_role = UserRole.new
    authorize! :create, @user
    add_breadcrumb t("controllers.users.add_member")
    respond_with @user
  end

  def edit
    @user = User.with_deleted.find(params[:id])
    add_breadcrumb t("controllers.users.user", name: @user.name)

    flash.now[:warning] = t('devise.failure.unconfirmed_admin') unless @user.confirmed?
    flash.now[:alert] = t("controllers.users.user_is_inactive") if @user.deleted?
  end

  def change_password
    edit
    add_breadcrumb t("controllers.users.change_password")
  end

  def create
    @user = User.new(user_params.merge(created_by_user: current_user))
    @user.corporate_id = current_user.corporate.id if current_user.corporate?

    if user = User.find_by(email: user_params[:email])  # user with this email already exists
      if current_user.corporate?
        if user.corporate_id?
          flash.now[:error] = "A user with the email #{@user.email} is already corporate user."
          render action: 'new'
        else
          invitation = JoinInvitation.create(sender: current_user, invitee: user, targetable: current_user.corporate)
          Mailer.delay.join_invitation(invitation.id)
          redirect_to users_path, notice: 'User was invited to join this corporate.'
        end
      else
        if user.properties.include? current_property # they are already connected to this property
          flash.now[:error] = "A user with the email #{@user.email} already exists in this hotel."
          render action: 'new'
        else # user exists but isn't connected to this property so let's invite them
          invitation = JoinInvitation.create(sender: current_user, invitee: user, targetable: current_property, params: params["user"].except("avatar", "name"))
          Mailer.delay.join_invitation(invitation.id)
          redirect_to users_path, notice: 'User was invited to join this hotel.'
        end
      end
    else #create a new user
      if @user.save
        redirect_to users_path, notice: t("controllers.users.user_was_created")
      else
        render action: 'new'
      end
    end
  end

  def update
    restore = params["submit_button"] == "Activate"
    inactivate = params["submit_button"] == "Inactivate"

    @user = User.with_deleted.find(params[:id])
    # TODO https://github.com/rails/rails/issues/6127
    settings = params[:user].delete :settings
    if settings
      @user.settings ||= {}
      @user.settings.merge! settings
      @user.settings_will_change!
      @user.save

      respond_with @user, location: policy(User).index? ? users_path : edit_user_path(@user) and return if params[:user].blank?
    end
    if @user.update(user_params)
      (restore && @user.activate!) || (inactivate && @user.inactivate!)
      flash[:notice] = t("controllers.users.user_was_updated") unless request.xhr?
      respond_with @user, location: policy(User).index? ? users_path : edit_user_path(@user)
    else
      changing_password = params[:user][:password].present?
      action = changing_password ? 'change_password' : 'edit'
      render action: action
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.inactivate!
    redirect_to users_url, notice: t("controllers.users.user_was_inactivated")
  end

  private

  # @param [String, Symbol] scope_name The name of the scope desired.
  #   Defaults to 'current_property' if nil or not provided.
  #
  # @return [Hash{String => Hash}] A hash describing the scope.  Contains
  #   a :required_permission which provides the Permission symbol needed
  #   on User to view it, and a :users key which provides a proc which,
  #   when called, yields a Relation with the users for the scope.
  def index_scope(scope_name = nil)
    { 'all' => {required_permission: :manage, users: proc{User.all} },
      'deleted' => {required_permission: :manage, users: proc{User.only_deleted} },
      'active' => {required_permission: :read, users: proc{current_property.users.where.not(confirmed_at: nil) }},
      'current_property' => {required_permission: :read, users: proc{current_property.users} }
    }[(scope_name || 'current_property').to_s]
  end

  def check_permissions
    authorize!(params[:action].to_sym, @user || User)
  end
end
