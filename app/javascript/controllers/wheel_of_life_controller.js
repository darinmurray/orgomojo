import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categoryForm", "resultsContainer", "responseText", "submitButton"]
  static values = { 
    currentCategory: String
  }

  connect() {
    console.log("Wheel of Life controller connected")
    
    // Load categories data from script tag
    const categoriesScript = document.getElementById('categories-data')
    if (categoriesScript) {
      try {
        this.categoriesData = JSON.parse(categoriesScript.textContent)
        console.log("Categories loaded:", this.categoriesData)
      } catch (error) {
        console.error("Error parsing categories data:", error)
        this.categoriesData = []
      }
    } else {
      console.error("Categories data script not found")
      this.categoriesData = []
    }
  }

  // Action: Select a life category slice
  selectCategory(event) {
    event.preventDefault()
    const categoryId = event.currentTarget.dataset.categoryId
    this.currentCategoryValue = categoryId
    
    // Remove active class from all slices
    this.element.querySelectorAll('.category-slice').forEach(slice => {
      slice.classList.remove('active')
    })
    
    // Add active class to selected slice
    event.currentTarget.classList.add('active')
    
    this.showCategoryForm(categoryId)
  }

  // Action: Submit the user's response
  async submitResponse(event) {
    event.preventDefault()
    
    const responseText = this.responseTextTarget.value
    
    if (!responseText.trim()) {
      alert('Please share your thoughts before submitting.')
      return
    }

    this.showLoading()

    try {
      const response = await fetch('/wheel_of_life/process_response', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          category_id: this.currentCategoryValue,
          response_text: responseText
        })
      })

      const data = await response.json()

      if (data.success) {
        this.displayResults(data)
        
        // Play audio summary if available
        if (data.audio_url) {
          setTimeout(() => {
            this.playAudio(data.audio_url)
          }, 1000)
        }
      } else {
        alert('Error: ' + data.error)
      }
    } catch (error) {
      console.error('Error:', error)
      alert('An error occurred while processing your response.')
    } finally {
      this.hideLoading()
    }
  }

  // Action: Play audio summary
  playAudio(event) {
    const audioUrl = event.currentTarget.dataset.audioUrl
    const audio = new Audio(audioUrl)
    audio.play().catch(error => {
      console.error('Audio playback failed:', error)
    })
  }

  // Private methods
  showCategoryForm(categoryId) {
    const categoryData = this.getCategoryData(categoryId)
    
    const formHtml = `
      <div class="category-assessment">
        <h3>${categoryData.name}</h3>
        <p class="prompt">${categoryData.prompt}</p>
        <textarea 
          data-wheel-of-life-target="responseText"
          placeholder="Share your thoughts about this area of your life..."
          rows="6" 
          class="form-control">
        </textarea>
        <button 
          data-wheel-of-life-target="submitButton"
          data-action="click->wheel-of-life#submitResponse"
          class="btn btn-primary mt-3">
          Analyze My Response
        </button>
      </div>
    `
    
    this.categoryFormTarget.innerHTML = formHtml
  }

  displayResults(data) {
    const resultsHtml = `
      <div class="analysis-results">
        <h4>Your Life Area Analysis</h4>
        
        <div class="overall-satisfaction mb-3">
          <strong>Overall Assessment:</strong>
          <p>${data.overall_satisfaction}</p>
        </div>

        <div class="row">
          <div class="col-md-6">
            <div class="working-well">
              <h5 class="text-success">✅ What's Working Well</h5>
              <ul>
                ${Array.isArray(data.analysis.working_well) ? 
                  data.analysis.working_well.map(item => `<li>${item}</li>`).join('') : 
                  '<li>No specific strengths identified</li>'}
              </ul>
            </div>
          </div>

          <div class="col-md-6">
            <div class="needs-improvement">
              <h5 class="text-warning">🎯 Areas for Growth</h5>
              <ul>
                ${Array.isArray(data.analysis.needs_improvement) ? 
                  data.analysis.needs_improvement.map(item => `<li>${item}</li>`).join('') : 
                  '<li>No areas for improvement identified</li>'}
              </ul>
            </div>
          </div>
        </div>

        ${Array.isArray(data.goals) && data.goals.length > 0 ? this.renderGoals(data.goals) : ''}

        ${data.audio_url ? `
          <div class="audio-summary mt-4">
            <button 
              class="btn btn-info" 
              data-action="click->wheel-of-life#playAudio"
              data-audio-url="${data.audio_url}">
              🔊 Play Audio Summary
            </button>
          </div>
        ` : ''}
      </div>
    `

    this.resultsContainerTarget.innerHTML = resultsHtml
  }

  renderGoals(goals) {
    return `
      <div class="actionable-goals mt-4">
        <h5 class="text-primary">🎯 Your Personalized Action Goals</h5>
        <div class="goals-list">
          ${goals.map(goal => `
            <div class="goal-card border rounded p-3 mb-3">
              <h6 class="goal-title">${goal.title}</h6>
              <p class="goal-description">${goal.description}</p>
              <div class="goal-details">
                <small class="text-muted">
                  <strong>Timeframe:</strong> ${goal.timeframe} |
                  <strong>Success Metric:</strong> ${goal.success_metric}
                </small>
              </div>
              <div class="challenge-addressed mt-2">
                <small><em>Addresses: ${goal.addresses_challenge}</em></small>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    `
  }

  showLoading() {
    this.submitButtonTarget.innerHTML = 'Analyzing... ⏳'
    this.submitButtonTarget.disabled = true
  }

  hideLoading() {
    this.submitButtonTarget.innerHTML = 'Analyze My Response'
    this.submitButtonTarget.disabled = false
  }

  getCategoryData(categoryId) {
    // Get category data from the loaded categories or fall back to defaults
    const categories = this.categoriesData || []
    const category = categories.find(cat => cat.id.toString() === categoryId.toString())
    return category || {
      name: 'Category Name',
      prompt: 'Category prompt here...'
    }
  }
}