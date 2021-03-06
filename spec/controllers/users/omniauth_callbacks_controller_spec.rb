require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  mock_devise

  describe 'GET #hpiopenid' do

    before :each do
      @user = FactoryBot.create(:user, uid: '1234567890', provider: 'hpiopenid')
      @auth = OmniAuth::AuthHash.new(
        provider: @user.provider,
        uid: @user.uid,
        info: { email: @user.email }
      )
      @request.env['omniauth.auth'] = @auth
    end

    context 'given a linked user' do
      it 'should redirect to the user dashboard' do
        get :hpiopenid
        expect(response).to redirect_to(dashboard_user_path(@user))
      end
    end

    context 'given an unlinked, logged in user' do
      it 'should link the accounts' do
        @user.uid = nil
        @user.provider = nil
        @user.save!
        sign_in @user
        get :hpiopenid
        @user.reload
        expect(response).to redirect_to(user_path(@user))
        expect(@user.uid).to eq(@auth.uid)
        expect(@user.provider).to eq(@auth.provider)
      end

      it 'should not link the accounts when the omniauth is already used' do
        @user2 = FactoryBot.create(:user)
        sign_in @user2
        get :hpiopenid
        @user.reload
        expect(response).to redirect_to(user_path(@user2))
        expect(@user2.uid).to be_nil
        expect(@user2.provider).to be_nil
      end
    end

    context 'given a linked, logged in user' do
      it 'should not change the users omniauth' do
        sign_in @user
        @request.env['omniauth.auth'] = OmniAuth::AuthHash.new(
          provider: @user.provider + '*',
          uid: @user.uid + '*',
          info: { email: @user.email }
        )
        get :hpiopenid
        expect(response).to redirect_to(user_path(@user))
        expect(@user.uid).to eq(@auth.uid)
        expect(@user.provider).to eq(@auth.provider)
      end
    end

    context 'given no (logged in or linked) user' do
      it 'should redirect to the registration form if information is missing' do
        @user.uid = nil
        @user.provider = nil
        @user.save!
        get :hpiopenid
        expect(response).to redirect_to(new_user_registration_path)
      end

      it 'should redirect to the dashboard if no information is missing' do
        @user.uid = nil
        @user.provider = nil
        @user.save!
        @auth.info[:email] = 'Horst@Peter.de'
        @auth.info[:first_name] = 'Horst'
        @auth.info[:last_name] = 'Peter'
        @request.env['omniauth.auth'] = @auth
        get :hpiopenid
        expect(response).to redirect_to(dashboard_user_path(User.last))
      end
    end
  end
end
