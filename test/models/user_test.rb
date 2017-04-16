require "test_helper"

describe User do
  before do
    @property = create(:property)
    @property.switch!
    @user = create(:user, current_property_role: Role.gm)
    @property1 = create(:property)
    @property1.switch!
    @user.user_roles << create(:user_role, role: Role.gm)
  end

  describe '#inactivate!' do
    it "should soft delete only current property's role" do
      @property.switch!
      @user.inactivate!
      @user.user_roles.with_deleted.where(property_id: @property.id).first.deleted_at.wont_be_nil
      @user.user_roles.empty?.must_equal false

      @user.all_properties.count.must_equal 1

      email = @user.email
      @property1.switch!
      @user.inactivate!

      @user.reload
      @user.email.must_equal 'inactive_' + email
      @user.deleted_at.wont_be_nil
    end
  end
end