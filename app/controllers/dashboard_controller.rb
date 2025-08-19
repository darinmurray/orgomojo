class DashboardController < ApplicationController
  def index
    if user_signed_in?
      # User is logged in - show their dashboard
      @user = current_user
      @pies = current_user.pies if current_user.pies.exists?
    else
      # User is not logged in - show landing page with login
      render "landing"
    end
  end

  def storyline
    # Static storyline page - accessible to all users
  end
end
