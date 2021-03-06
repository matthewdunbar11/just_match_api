# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Users::UserLanguagesController, type: :controller do
  let(:valid_attributes) do
    {}
  end

  let(:invalid_attributes) do
    {}
  end

  let(:user) { FactoryGirl.create(:user_with_tokens) }

  describe 'GET #index' do
    it 'assigns all user languages as @languages' do
      user = FactoryGirl.create(:user_with_languages, languages_count: 1)
      user.create_auth_token
      user.user_languages.first.update(proficiency: 3)

      user_language = user.user_languages.first
      get :index, params: { auth_token: user.auth_token, user_id: user.to_param }
      expect(assigns(:user_languages)).to eq([user_language])
    end
  end

  describe 'GET #show' do
    it 'assigns @language, @user @user_language' do
      user = FactoryGirl.create(:user_with_languages, languages_count: 1)
      language = user.languages.first
      user_language = user.user_languages.first
      params = {
        auth_token: user.auth_token,
        user_id: user.to_param,
        user_language_id: user_language.to_param
      }
      get :show, params: params
      expect(assigns(:language)).to eq(language)
      expect(assigns(:user_language)).to eq(user_language)
      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:proficiency) { 4 }
      let(:language) { FactoryGirl.create(:language) }
      let(:params) do
        {
          auth_token: user.auth_token,
          user_id: user.to_param,
          data: {
            attributes: {
              id: language.to_param,
              proficiency: proficiency
            }
          }
        }
      end

      it 'creates a new UserLanguage' do
        expect do
          post :create, params: params
        end.to change(UserLanguage, :count).by(1)
      end

      it 'assigns a newly created user_language as @user_language' do
        post :create, params: params
        expect(assigns(:user_language)).to be_a(UserLanguage)
        expect(assigns(:user_language)).to be_persisted
      end

      it 'sets proficiency' do
        post :create, params: params
        expect(assigns(:user_language).proficiency).to eq(proficiency)
      end

      it 'returns created status' do
        post :create, params: params
        expect(response.status).to eq(201)
      end

      context 'not authorized' do
        let(:other_user) { FactoryGirl.create(:user) }
        let(:params) do
          {
            auth_token: user.auth_token,
            user_id: other_user.to_param,
            data: {
              attributes: {
                id: language.to_param,
                proficiency: proficiency
              }
            }
          }
        end

        it 'returns created status' do
          post :create, params: params
          expect(response.status).to eq(403)
        end
      end
    end

    context 'with invalid params' do
      let(:params) do
        {
          auth_token: user.auth_token,
          user_id: user.to_param,
          language: { id: nil }
        }
      end

      it 'assigns a newly created but unsaved user_language as @user_language' do
        post :create, params: params
        expect(assigns(:user_language)).to be_a_new(UserLanguage)
      end

      it 'returns unprocessable entity status' do
        post :create, params: params
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'authorized' do
      it 'destroys the requested user_language' do
        user_language = FactoryGirl.create(:user_language, user: user)
        params = {
          auth_token: user.auth_token,
          user_id: user.to_param,
          user_language_id: user_language.to_param
        }
        expect do
          delete :destroy, params: params
        end.to change(UserLanguage, :count).by(-1)
      end

      it 'returns no content status' do
        user_language = FactoryGirl.create(:user_language, user: user)
        params = {
          auth_token: user.auth_token,
          user_id: user.to_param,
          user_language_id: user_language.to_param
        }
        delete :destroy, params: params
        expect(response.status).to eq(204)
      end
    end

    context 'not authorized' do
      it 'does not destroys the requested user_language' do
        other_user = FactoryGirl.create(:user_with_tokens)
        user = FactoryGirl.create(:user_with_languages)
        user_language = user.user_languages.first
        params = {
          auth_token: other_user.auth_token,
          user_id: user.to_param,
          user_language_id: user_language.to_param
        }
        expect do
          delete :destroy, params: params
        end.to change(UserLanguage, :count).by(0)
      end

      it 'returns not authorized error' do
        other_user = FactoryGirl.create(:user_with_tokens)
        user = FactoryGirl.create(:user_with_languages)
        user_language = user.user_languages.first
        params = {
          auth_token: other_user.auth_token,
          user_id: user.to_param,
          user_language_id: user_language.to_param
        }
        delete :destroy, params: params
        expect(response.status).to eq(403)
      end
    end
  end
end
