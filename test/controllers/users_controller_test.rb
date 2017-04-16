require 'test_helper'

describe UsersController do
  include Devise::TestHelpers

  describe "POST#create" do
    let(:user){ create(:user, current_property_role: Role.gm) }

    before do
      sign_in user
    end

    it "sends an invitation email if a user with this email already exists but is connected to another hotel" do
      user_params = { "name"=>"Test User", "current_property_user_role_attributes"=>{"title"=>"Test User", "role_id"=>Role.gm.id}, "email"=>"test_user@example.com", "department_ids"=>["", Department.first.id], "order_approval_limit"=>"0"} 
      create(:property).run_block do
        create(:user, email: user_params["email"])
      end

      assert_equal 0, Sidekiq::Extensions::DelayedMailer.jobs.size

      post :create, user: user_params
      flash[:notice].must_equal 'User was invited to join this hotel.'
      assert_redirected_to users_path
      assert_equal 1, Sidekiq::Extensions::DelayedMailer.jobs.size
    end
  end

  describe "permissions" do
    before do
      create_list(:user, 5)
    end

    let(:user_params) { { "name"=>"Test User", "current_property_user_role_attributes"=>{"title"=>"Test User", "role_id"=>Role.gm.id}, "email"=>"test_user@example.com", "department_ids"=>["", Department.first.id], "order_approval_limit"=>"0"} }

    describe "corporate" do
      let(:user){ create(:user, current_property_role: Role.corporate) }

      before do
        sign_in user
      end

      describe "GET#new" do
        it "corporate should have new access" do
          get :new
          assert_response :success
        end
      end

      describe "POST#create" do
        it "corporate should have create access" do
          post :create, user: user_params
          flash[:notice].must_equal 'User was successfully created.'
          assert_redirected_to users_path
        end
      end

      describe "GET#edit" do
        it "corporate should have edit access" do
          get :edit, id: User.first.id
          assert_response :success
        end

        it 'should not allow to edit invited user' do
          invitee = nil
          create(:property).run_block do
            invitee = create(:user)
          end
          create(:join_invitation, targetable: Property.current, sender: user, invitee: invitee)
          get :edit, id: invitee.id
          assert_redirected_to authenticated_root_path
        end
      end

      describe "PUT#update" do
        it 'should not allow to edit corporate' do
          property_id = Property.current_id
          Property.current_id = nil
          corporate = create(:corporate, name: "CORP1")
          corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
          Property.current_id = property_id
          # Property.current.update_attributes(corporate_id: corporate.id)
          create(:corporate_connection, corporate: corporate, email: corp_user.email, property: Property.current, state: :new, created_by: user)
          put :update, user: {name: "NEW"}, id: User.last.id
          assert_redirected_to authenticated_root_path
        end
      end

      describe "DELETE#destroy" do
        it 'should not allow to delete corporate' do
          property_id = Property.current_id
          Property.current_id = nil
          corporate = create(:corporate, name: "CORP1")
          corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
          Property.current_id = property_id
          # Property.current.update_attributes(corporate_id: corporate.id)
          create(:corporate_connection, corporate: corporate, email: corp_user.email, property: Property.current, state: :new, created_by: user)
          delete :destroy, id: User.last.id
          assert_redirected_to authenticated_root_path
        end

        it "corporate should have delete access" do
          delete :destroy, id: User.last.id
          flash[:notice].must_equal 'User was successfully inactivated.'
          assert_redirected_to users_path
        end
      end
    end

    describe "agm" do
      let(:user){ create(:user, current_property_role: Role.agm) }

      before do
        sign_in user
      end

      describe "GET#new" do
        it "agm should not have new access" do
          get :new
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
        end
      end

      describe "GET#edit" do
        it 'should not allow to edit invited user' do
          invitee = nil
          create(:property).run_block do
            invitee = create(:user)
          end
          create(:join_invitation, targetable: Property.current, sender: user, invitee: invitee)
          get :edit, id: invitee.id
          assert_redirected_to authenticated_root_path
        end

        it "agm should not have edit access" do
          get :edit, id: User.first.id
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
        end
      end

      describe "PUT#update" do
        it 'should not allow to edit corporate' do
          property_id = Property.current_id
          Property.current_id = nil
          corporate = create(:corporate, name: "CORP1")
          corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
          Property.current_id = property_id
          # Property.current.update_attributes(corporate_id: corporate.id)
          create(:corporate_connection, corporate: corporate, email: corp_user.email, property: Property.current, state: :new, created_by: user)
          put :update, user: {name: "NEW"}, id: User.last.id
          assert_redirected_to authenticated_root_path
        end

        it "agm should not have put access" do
          put :update, user: {name: "NEW"}, id: User.first.id
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
        end
      end

      describe "DELETE#destroy" do
        it 'should not allow to delete corporate' do
          property_id = Property.current_id
          Property.current_id = nil
          corporate = create(:corporate, name: "CORP1")
          corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
          Property.current_id = property_id
          # Property.current.update_attributes(corporate_id: corporate.id)
          create(:corporate_connection, corporate: corporate, email: corp_user.email, property: Property.current, state: :new, created_by: user)
          delete :destroy, id: User.last.id
          assert_redirected_to authenticated_root_path
        end

        it "agm should not have delete access" do
          delete :destroy, id: User.last.id
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
        end
      end
    end

    describe "gm" do
      let(:user){ create(:user, current_property_role: Role.gm) }

      before do
        sign_in user
      end

      describe "GET#new" do
        it "gm should have new access" do
          get :new
          assert_response :success
        end
      end

      describe "POST#create" do
        it "gm should have create access" do
          post :create, user: user_params
          flash[:notice].must_equal 'User was successfully created.'
          assert_redirected_to users_path
        end
      end

      describe "GET#edit" do
        it 'should not allow to edit invited user' do
          invitee = nil
          create(:property).run_block do
            invitee = create(:user)
          end
          create(:join_invitation, targetable: Property.current, sender: user, invitee: invitee)
          get :edit, id: invitee.id
          assert_redirected_to authenticated_root_path
        end

        it "gm should have edit access" do
          get :edit, id: User.first.id
          assert_response :success
        end
      end

      describe "PUT#update" do
        it 'should not allow to update corporate' do
          property_id = Property.current_id
          Property.current_id = nil
          corporate = create(:corporate, name: "CORP1")
          corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
          Property.current_id = property_id
          # Property.current.update_attributes(corporate_id: corporate.id)
          create(:corporate_connection, corporate: corporate, email: corp_user.email, property: Property.current, state: :new, created_by: user)
          put :update, user: {name: "NEW"}, id: User.last.id
          assert_redirected_to authenticated_root_path
        end
      end

      describe "DELETE#destroy" do
        it 'should not allow to delete corporate' do
          property_id = Property.current_id
          Property.current_id = nil
          corporate = create(:corporate, name: "CORP1")
          corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
          Property.current_id = property_id
          # Property.current.update_attributes(corporate_id: corporate.id)
          create(:corporate_connection, corporate: corporate, email: corp_user.email, property: Property.current, state: :new, created_by: user)
          delete :destroy, id: User.last.id
          assert_redirected_to authenticated_root_path
        end

        it "gm should have delete access" do
          delete :destroy, id: User.last.id
          flash[:notice].must_equal 'User was successfully inactivated.'
          assert_redirected_to users_path
        end
      end
    end

    describe "manager" do
      let(:user){ create(:user, current_property_role: Role.manager) }

      before do
        sign_in user
      end

      describe "GET#new" do
        it "manager should not have new access" do
          get :new
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
        end
      end

      describe "POST#create" do
        it "manager should not have create access" do
          post :create, user: user_params.merge!("name" => "New User1")
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
          User.last.name.wont_equal "New User1"
        end
      end

      describe "GET#edit" do
        it 'should not allow to edit invited user' do
          invitee = nil
          create(:property).run_block do
            invitee = create(:user)
          end
          create(:join_invitation, targetable: Property.current, sender: user, invitee: invitee)
          get :edit, id: invitee.id
          assert_redirected_to authenticated_root_path
        end

        it "manager should not have edit access" do
          get :edit, id: User.first.id
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
        end
      end

      describe "PUT#update" do
        it 'should not allow to update corporate' do
          property_id = Property.current_id
          Property.current_id = nil
          corporate = create(:corporate, name: "CORP1")
          corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
          Property.current_id = property_id
          # Property.current.update_attributes(corporate_id: corporate.id)
          create(:corporate_connection, corporate: corporate, email: corp_user.email, property: Property.current, state: :new, created_by: user)
          put :update, user: {name: "NEW"}, id: User.last.id
          assert_redirected_to authenticated_root_path
        end

        it "manager should not have put access" do
          put :update, user: {name: "NEW"}, id: User.first.id
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
        end
      end

      describe "DELETE#destroy" do
        it 'should not allow to delete corporate' do
          property_id = Property.current_id
          Property.current_id = nil
          corporate = create(:corporate, name: "CORP1")
          corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
          Property.current_id = property_id
          # Property.current.update_attributes(corporate_id: corporate.id)
          create(:corporate_connection, corporate: corporate, email: corp_user.email, property: Property.current, state: :new, created_by: user)
          delete :destroy, id: User.last.id
          assert_redirected_to authenticated_root_path
        end

        it "manager should not have delete access" do
          delete :destroy, id: User.first.id
          flash[:alert].must_equal "You are not authorized to access this page."
          assert_redirected_to authenticated_root_path
        end
      end
    end
  end
end
