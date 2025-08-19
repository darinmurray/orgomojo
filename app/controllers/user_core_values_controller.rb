class UserCoreValuesController < ApplicationController
  before_action :authenticate_user!

  # PATCH /user_core_values/update_importance_levels
  def update_importance_levels
    updates = params[:updates]

    if updates.present?
      updates.each do |update|
        user_core_value = current_user.user_core_values.find(update[:id])
        user_core_value.update(importance_level: update[:importance_level])
      end

      render json: { success: true, message: "Importance levels updated successfully." }
    else
      render json: { success: false, message: "No updates provided." }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "One or more values not found." }
  rescue StandardError
    render json: { success: false, message: "Failed to update importance levels." }
  end

  # DELETE /user_core_values/:id
  def destroy
    @user_core_value = current_user.user_core_values.find(params[:id])
    core_value_name = @user_core_value.core_value.name

    @user_core_value.destroy

    respond_to do |format|
      format.html { redirect_to core_values_path, notice: "#{core_value_name} has been removed from your values." }
      format.json { render json: { success: true, message: "#{core_value_name} has been removed from your values." } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to core_values_path, alert: "Value not found." }
      format.json { render json: { success: false, message: "Value not found." } }
    end
  end
end
