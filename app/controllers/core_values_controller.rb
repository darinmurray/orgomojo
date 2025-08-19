class CoreValuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_core_value, only: %i[show edit update destroy]

  # GET /core_values
  def index
    @user_core_values = current_user.user_core_values.includes(:core_value).by_importance
    @all_core_values = CoreValue.all.order(:name)
    @available_core_values = @all_core_values.where.not(id: @user_core_values.pluck(:core_value_id))
  end

  # POST /core_values/add_to_user
  def add_to_user
    @core_value = CoreValue.find(params[:core_value_id])
    @user_core_value = current_user.user_core_values.build(
      core_value: @core_value,
      importance_level: params[:importance_level] || 5
    )

    respond_to do |format|
      if @user_core_value.save
        format.html { redirect_to core_values_path, notice: "#{@core_value.name} has been added to your values." }
        format.json {
          render json: {
            success: true,
            message: "#{@core_value.name} has been added to your values.",
            core_value: {
              id: @core_value.id,
              name: @core_value.name,
              description: @core_value.description,
              user_core_value_id: @user_core_value.id
            }
          }
        }
      else
        format.html { redirect_to core_values_path, alert: "Unable to add this value. It may already be in your list." }
        format.json {
          render json: {
            success: false,
            message: "Unable to add this value. It may already be in your list."
          }
        }
      end
    end
  end



  # GET /core_values/:id
  def show
  end

  # GET /core_values/new
  def new
    @core_value = CoreValue.new
  end

  # POST /core_values
  def create
    @core_value = CoreValue.new(core_value_params)

    if @core_value.save
      redirect_to @core_value, notice: "Core Value was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /core_values/:id/edit
  def edit
  end

  # PATCH/PUT /core_values/:id
  def update
    if @core_value.update(core_value_params)
      redirect_to @core_value, notice: "Core Value was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /core_values/:id
  def destroy
    @core_value.destroy
    redirect_to core_values_url, notice: "Core Value was successfully destroyed."
  end

  private

  def set_core_value
    @core_value = CoreValue.find(params[:id])
  end

  def core_value_params
    params.require(:core_value).permit(:name, :description, examples: [])
  end
end
