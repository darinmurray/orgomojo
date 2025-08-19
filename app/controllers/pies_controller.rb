class PiesController < ApplicationController
  before_action :authenticate_user!  # Add this line
  before_action :set_pie, only: [ :show, :edit, :update, :destroy ]

  def index
    @pies = current_user.pies  # Scope to current user's pies
  end

  def show
  end

  def new
    @pie = current_user.pies.build
    # No need to build slices here - wizard handles everything
  end

  def create
    Rails.logger.debug "=== PIE CREATION START ==="
    Rails.logger.debug "Content-Type: #{request.content_type}"
    Rails.logger.debug "Request format: #{request.format}"
    Rails.logger.debug "Raw params: #{params.inspect}"

    begin
      @pie = current_user.pies.build(pie_params)
      Rails.logger.debug "Pie params: #{pie_params.inspect}"
      Rails.logger.debug "Pie valid? #{@pie.valid?}"
      Rails.logger.debug "Pie errors: #{@pie.errors.full_messages}" unless @pie.valid?

      if @pie.save
        Rails.logger.debug "Pie saved successfully with ID: #{@pie.id}"
        Rails.logger.debug "Pie slices count: #{@pie.slices.count}"
        Rails.logger.debug "Total elements count: #{@pie.elements.count}"

        respond_to do |format|
          format.html { redirect_to @pie, notice: "Pie was successfully created." }
          format.json {
            Rails.logger.debug "Returning JSON response for pie ID: #{@pie.id}"
            render json: { id: @pie.id, name: @pie.name, status: "success" }, status: :created
          }
        end
      else
        Rails.logger.debug "Failed to save pie. Errors: #{@pie.errors.full_messages}"
        respond_to do |format|
          format.html { render :new_wizard }
          format.json { render json: { errors: @pie.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    rescue => e
      Rails.logger.error "Exception in pie creation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      respond_to do |format|
        format.html { render :new_wizard }
        format.json { render json: { error: e.message }, status: :internal_server_error }
      end
    end
  end

  def edit
  end

  def update
    if @pie.update(pie_params)
      redirect_to @pie, notice: "Pie was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @pie.destroy
    redirect_to root_path, notice: "Pie was successfully deleted."
  end

  private

  def set_pie
    @pie = current_user.pies.find(params[:id])  # Scope to current user's pies
  end

  def pie_params
    params.require(:pie).permit(:name,
      slices_attributes: [ :id, :name, :percentage, :color, :_destroy,
        elements_attributes: [ :id, :name, :objective, :completed, :_destroy ] ])
  end
end
