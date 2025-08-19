# app/controllers/slices_controller.rb
class SlicesController < ApplicationController
  before_action :set_pie
  before_action :set_slice, only: [ :show, :edit, :update, :destroy ]

  def show
    @elements = @slice.elements.order(:completed, :priority, :id)
    # @elements = Element.order(:completed) # false first, then true
    # To reverse: .order(completed: :desc)
  end

  def edit
    # Build some empty elements if none exist
    3.times { @slice.elements.build } if @slice.elements.empty?
  end

  def update
    if @slice.update(slice_params)
      redirect_to [ @pie, @slice ], notice: "Slice was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @slice.destroy
    redirect_to @pie, notice: "Slice was successfully deleted."
  end

  private

  def set_pie
    @pie = Pie.find(params[:pie_id])
  end

  def set_slice
    @slice = @pie.slices.find(params[:id])
  end

  def slice_params
    params.require(:slice).permit(:name, :color, :objective, elements_attributes: [ :id, :name, :completed, :_destroy ])
  end
end
