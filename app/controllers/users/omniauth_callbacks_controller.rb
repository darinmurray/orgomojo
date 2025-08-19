class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      flash[:notice] = 'Successfully authenticated with Google.'
      sign_in_and_redirect @user, event: :authentication
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except('extra')
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: 'Authentication failed.'
  end
end



# Adding config/master.key to store the encryption key: af8acbc12ec6465385143d7460b9e10e
# Adding config/master.key to store the encryption key: af8acbc12ec6465385143d7460b9e10e
# Adding config/master.key to store the encryption key: af8acbc12ec6465385143d7460b9e10e
# Adding config/master.key to store the encryption key: af8acbc12ec6465385143d7460b9e10e
# Adding config/master.key to store the encryption key: af8acbc12ec6465385143d7460b9e10e