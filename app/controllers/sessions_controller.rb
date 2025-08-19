class SessionsController < ApplicationController
  def omniauth
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)
    
    if user.persisted?
      sign_in(user)
      redirect_to root_path, notice: 'Successfully signed in with Google!'
    else
      redirect_to root_path, alert: 'There was an error signing you in.'
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to root_path, notice: 'Signed out successfully!'
  end
end