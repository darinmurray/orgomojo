class WaysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_way, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_owner, only: [ :show, :edit, :update, :destroy ]

  def index
    @six_human_needs = SixHumanNeed.includes(ways: :user).ordered
    @ways_by_need = current_user.ways.includes(:six_human_need).group_by(&:six_human_need)
  end

  def show
  end

  def new
    @way = current_user.ways.build
    @six_human_need = SixHumanNeed.find(params[:six_human_need_id]) if params[:six_human_need_id]
    @way.six_human_need = @six_human_need if @six_human_need
  end

  def create
    @way = current_user.ways.build(way_params)

    # Debug logging
    Rails.logger.debug "Way params: #{way_params.inspect}"
    Rails.logger.debug "Way valid?: #{@way.valid?}"
    Rails.logger.debug "Way errors: #{@way.errors.full_messages}" unless @way.valid?

    if @way.save
      redirect_to ways_path, notice: "Way was successfully created."
    else
      @six_human_need = @way.six_human_need
      @six_human_need ||= SixHumanNeed.find(params[:six_human_need_id]) if params[:six_human_need_id]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @way.update(way_params)
      respond_to do |format|
        format.html { redirect_to ways_path, notice: "Way was successfully updated." }
        format.json { render json: { success: true, way: @way } }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: { success: false, error: @way.errors.full_messages.join(", ") } }
      end
    end
  end

  def destroy
    @way.destroy
    redirect_to ways_path, notice: "Way was successfully deleted."
  end

  private

  def set_way
    @way = Way.find(params[:id])
  end

  def ensure_owner
    redirect_to ways_path, alert: "Access denied." unless @way.user == current_user
  end

  def way_params
    params.require(:way).permit(:description, :six_human_need_id)
  end
end
