# app/controllers/elements_controller.rb
class ElementsController < ApplicationController
  before_action :set_pie_and_slice
  before_action :set_element, only: [ :edit, :update, :destroy, :toggle ]

  # POST /pies/:pie_id/slices/:slice_id/elements/:id/make_tangible
  def make_tangible
    @element = @slice.elements.find(params[:id])
    objective = params[:objective] || @element.name
    ai_rewriter = AiTextRewriter.new
    # Get tangible rewrite and reasoning
    result = ai_rewriter.make_it_tangible(objective)
    lines = result.to_s.split("\n")
    tangible_objective = lines.first&.strip
    reasoning = lines[1..-1]&.join("\n")&.strip
    # Also get AI rewrite (for comparison)
    rewritten_name = ai_rewriter.rewrite_element(objective, @element.pie_slice.name)
    render json: { tangible_objective: tangible_objective, reasoning: reasoning, rewritten_name: rewritten_name }
  end


  def toggle
    @element.update!(completed: !@element.completed)

    respond_to do |format|
      format.html { redirect_back(fallback_location: @pie) }
      format.turbo_stream { render :toggle }
    end
  end



  def create
    @element = @slice.elements.build(element_params)

    if @element.save
      # Determine outcome_type using AI after saving
      ai_rewriter = AiTextRewriter.new
      outcome_type = ai_rewriter.habit_or_milestone(@element.name)
      @element.update(outcome_type: outcome_type)

      render json: {
        success: true,
        element: {
          id: @element.id,
          name: @element.name,
          objective: @element.objective,
          outcome_type: @element.outcome_type
        }
      }
    else
      render json: {
        success: false,
        error: @element.errors.full_messages.join(", ")
      }
    end
  end

  def edit
  end




#   def update
#   if @element.update(element_params)
#     respond_to do |format|
#       format.html { redirect_to [@pie, @slice] }
#       format.js { head :ok }  # For AJAX requests, just return success
#     end
#   else
#     respond_to do |format|
#       format.html { render :edit }
#       format.js { head :unprocessable_entity }
#     end
#   end
# end



def update
  # Handle AI objective generation with custom word count
  if element_params[:objective]&.strip&.downcase == "help" && params[:word_count].present?
    word_count = params[:word_count].to_i
    @element.skip_ai_generation! # Prevent model callback from interfering
    ai_objective = AiTextRewriter.new.suggest_objective(@element, word_count)
    @element.objective = ai_objective
    @element.save
  # Handle AI element name rewriting
  elsif element_params[:name]&.strip&.downcase == "rewrite_element"
    ai_rewriter = AiTextRewriter.new
    original_name = @element.name
    slice_name = @element.pie_slice.name
    rewritten_name = ai_rewriter.rewrite_element(original_name, slice_name)
    habit_or_milestone = ai_rewriter.habit_or_milestone(rewritten_name)
    @element.name = rewritten_name
    @element.outcome_type = habit_or_milestone

    # Check tangibility with reasoning and store the result
    tangibility_response = ai_rewriter.check_tangibility(@element.name, include_reasoning: true)
    tangibility_lines = tangibility_response&.split("\n") || []
    tangibility_decision = tangibility_lines.first&.strip&.downcase == "true"
    tangibility_reasoning = tangibility_lines[1..-1]&.join("\n")&.strip

    @element.tangible = tangibility_decision
    @element.save

    # Store reasoning for response
    @tangibility_reasoning = tangibility_reasoning
  elsif @element.update(element_params)
    # Normal update path - check tangibility if name was updated
    if params[:make_tangible].present? && @element.tangible == false
      ai_rewriter = AiTextRewriter.new
      tangible_result = ai_rewriter.make_it_tangible(@element.name)
      tangible_lines = tangible_result.to_s.split("\n")
      tangible_objective = tangible_lines.first&.strip
      tangible_reasoning = tangible_lines[1..-1]&.join("\n")&.strip
      @element.name = tangible_objective
      @element.tangible = true
      @element.save
      @tangibility_reasoning = tangible_reasoning
      @tangible_objective = tangible_objective
    elsif element_params[:name].present? && @element.saved_change_to_name?
      ai_rewriter = AiTextRewriter.new

      # Check tangibility
      tangibility_response = ai_rewriter.check_tangibility(@element.name, include_reasoning: true)
      tangibility_lines = tangibility_response&.split("\n") || []
      tangibility_decision = tangibility_lines.first&.strip&.downcase == "true"
      tangibility_reasoning = tangibility_lines[1..-1]&.join("\n")&.strip

      # Fallback if reasoning is blank
      if tangibility_reasoning.blank?
        if tangibility_decision
          tangibility_reasoning = "This objective is tangible because it describes a specific, measurable outcome."
        else
          tangibility_reasoning = "This objective is intangible because it describes a state of being, mindset, or habit, rather than a specific, measurable result."
        end
      end

      # Determine if it's a habit or milestone
      outcome_type = ai_rewriter.habit_or_milestone(@element.name)

      @element.tangible = tangibility_decision
      @element.outcome_type = outcome_type
      @element.save
      @tangibility_reasoning = tangibility_reasoning
    end
  else
    # Handle update failure
  end

  if @element.persisted? && @element.errors.empty?
    respond_to do |format|
      format.html { redirect_to [ @pie, @slice ] }
      format.json {
        # Return the updated element data, including AI-generated objective
        response_data = {
          success: true,
          element: {
            id: @element.id,
            name: @element.name,
            objective: @element.objective,
            completed: @element.completed,
            tangible: @element.tangible,
            outcome_type: @element.outcome_type
          }
        }

        # Include tangibility reasoning if available
        if @tangibility_reasoning.present?
          response_data[:tangibility_reasoning] = @tangibility_reasoning
        else
          # Fallback for legacy/edge cases
          response_data[:tangibility_reasoning] = "No explanation provided by AI."
        end

        # If tangible_objective is present, include it in the response
        if defined?(@tangible_objective) && @tangible_objective.present?
          response_data[:tangible_objective] = @tangible_objective
        end
        render json: response_data
      }
      format.js { head :ok }  # For any other AJAX requests
    end
  else
    respond_to do |format|
      format.html { render :edit }
      format.json {
        render json: {
          success: false,
          errors: @element.errors.full_messages
        }, status: :unprocessable_entity
      }
      format.js { head :unprocessable_entity }
    end
  end
end




  def destroy
    @element.destroy

    respond_to do |format|
      format.html { redirect_to @pie, notice: "Element was successfully deleted." }
      format.turbo_stream # This will render destroy.turbo_stream.erb
    end
  end

  def reorder
    element_ids = params[:element_ids]

    if element_ids.present?
      element_ids.each_with_index do |element_id, index|
        element = @slice.elements.find(element_id)
        element.update_column(:priority, index + 1)
      end

      render json: { success: true }
    else
      render json: { success: false, error: "No element IDs provided" }
    end
  end

  private

  def set_pie_and_slice
    @pie = Pie.find(params[:pie_id])
    @slice = @pie.slices.find(params[:slice_id])
  end

  def set_element
    @element = @slice.elements.find(params[:id])
  end

  def element_params
    params.require(:element).permit(:name, :completed, :priority, :time_needed, :time_scale, :cadence, :deadline, :objective, :outcome_type)
  end
end










# # app/controllers/elements_controller.rb
# class ElementsController < ApplicationController
#   before_action :set_pie_and_slice
#   before_action :set_element, only: [:edit, :update, :destroy, :toggle]

#   def toggle
#     @element.update!(completed: !@element.completed)
#     redirect_back(fallback_location: @pie)
#   end

#   def create
#     @element = @slice.elements.build(element_params)

#     respond_to do |format|
#       if @element.save
#         format.html { redirect_to @pie, notice: 'Element was successfully created.' }
#         format.turbo_stream # This will render create.turbo_stream.erb
#       else
#         format.html { redirect_to @pie, alert: "Error creating element: #{@element.errors.full_messages.join(', ')}" }
#         format.turbo_stream # This will also render create.turbo_stream.erb with errors
#       end
#     end
#   end

#   def edit
#   end

#   def update
#     if @element.update(element_params)
#       redirect_to @pie, notice: 'Element was successfully updated.'
#     else
#       render :edit
#     end
#   end

#   def destroy
#     @element.destroy
#     respond_to do |format|
#       format.html { redirect_to @pie, notice: 'Element was successfully deleted.' }
#       format.turbo_stream do
#         render turbo_stream: turbo_stream.remove("element-#{@element.id}")
#       end
#     end
#   end

#   private

#   def set_pie_and_slice
#     @pie = Pie.find(params[:pie_id])
#     @slice = @pie.slices.find(params[:slice_id])
#   end

#   def set_element
#     @element = @slice.elements.find(params[:id])
#   end

#   def element_params
#     params.require(:element).permit(:name, :completed)
#   end
# end

















# # app/controllers/elements_controller.rb
# class ElementsController < ApplicationController
#   before_action :set_pie_and_slice
#   before_action :set_element, only: [:edit, :update, :destroy, :toggle]

#   def toggle
#     @element.update!(completed: !@element.completed)
#     redirect_back(fallback_location: @pie)
#   end

#   def create
#     @element = @slice.elements.build(element_params)

#     respond_to do |format|
#       if @element.save
#         format.html { redirect_to @pie, notice: 'Element was successfully created.' }
#         format.turbo_stream { render turbo_stream: turbo_stream.append("slice-#{@slice.id}-elements", render_element_row(@element)) }
#         format.json { render json: { success: true, element: element_data(@element) } }
#       else
#         format.html { redirect_to @pie, alert: "Error creating element: #{@element.errors.full_messages.join(', ')}" }
#         format.turbo_stream { render turbo_stream: turbo_stream.replace("slice-#{@slice.id}-form", render_add_form_with_errors) }
#         format.json { render json: { success: false, errors: @element.errors.full_messages } }
#       end
#     end
#   end

#   def edit
#   end

#   def update
#     if @element.update(element_params)
#       redirect_to @pie, notice: 'Element was successfully updated.'
#     else
#       render :edit
#     end
#   end

#   def destroy
#     @element.destroy
#     respond_to do |format|
#       format.html { redirect_to @pie, notice: 'Element was successfully deleted.' }
#       format.turbo_stream { render turbo_stream: turbo_stream.remove("element-#{@element.id}") }
#       format.json { render json: { success: true } }
#     end
#   end

#   private

#   def set_pie_and_slice
#     @pie = Pie.find(params[:pie_id])
#     @slice = @pie.slices.find(params[:slice_id])
#   end

#   def set_element
#     @element = @slice.elements.find(params[:id])
#   end

#   def element_params
#     params.require(:element).permit(:name, :completed)
#   end

#   def element_data(element)
#     {
#       id: element.id,
#       name: element.name,
#       completed: element.completed,
#       slice_id: element.slice_id,
#       pie_id: @pie.id
#     }
#   end

#   def render_element_row(element)
#     render_to_string(partial: 'pies/element_row', locals: { pie: @pie, slice: @slice, element: element })
#   end

#   def render_add_form_with_errors
#     render_to_string(partial: 'pies/add_element_form', locals: { pie: @pie, slice: @slice, element: @element })
#   end
# end
