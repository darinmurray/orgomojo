class SettingsController < ApplicationController
  before_action :set_setting, only: [ :edit, :update ]

  def edit
  end

  def update
    if @setting.update(setting_params)
      redirect_to edit_setting_path(@setting), notice: "Settings were successfully updated."
    else
      render :edit
    end
  end

  private

  def set_setting
    @setting = current_user.setting
  end

  def setting_params
    params.require(:setting).permit(:gender, :tone_1, :tone_2, :timespan, :pie_objective_length, :slice_objective_length, :slice_element_length, :element_objective_length, :task_length, :task_outcome_length)
  end
end
