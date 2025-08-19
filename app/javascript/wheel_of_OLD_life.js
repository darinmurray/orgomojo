// Frontend JavaScript for wheel of life interface
//  app/assets/javascripts/wheel_of_life.js
class WheelOfLifeInterface {
  constructor() {
    this.currentCategory = null;
    this.setupEventListeners();
  }

  setupEventListeners() {
    // Category selection
    document.querySelectorAll('.category-slice').forEach(slice => {
      slice.addEventListener('click', (e) => {
        this.selectCategory(e.target.dataset.categoryId);
      });
    });

    // Response submission
    const submitBtn = document.getElementById('submit-response');
    if (submitBtn) {
      submitBtn.addEventListener('click', () => this.submitResponse());
    }

    // Audio playback
    document.addEventListener('click', (e) => {
      if (e.target.classList.contains('play-audio-btn')) {
        this.playAudio(e.target.dataset.audioUrl);
      }
    });
  }

  selectCategory(categoryId) {
    this.currentCategory = categoryId;
    
    // Update UI to show category form
    this.showCategoryForm(categoryId);
  }

  showCategoryForm(categoryId) {
    const categoryData = this.getCategoryData(categoryId);
    
    const formHtml = `
      <div class="category-assessment">
        <h3>${categoryData.name}</h3>
        <p class="prompt">${categoryData.prompt}</p>
        <textarea 
          id="response-text" 
          placeholder="Share your thoughts about this area of your life..."
          rows="6" 
          class="form-control">
        </textarea>
        <button id="submit-response" class="btn btn-primary mt-3">
          Analyze My Response
        </button>
      </div>
    `;
    
    document.getElementById('category-form').innerHTML = formHtml;
    
    // Re-attach event listener
    document.getElementById('submit-response').addEventListener('click', () => {
      this.submitResponse();
    });
  }

  async submitResponse() {
    const responseText = document.getElementById('response-text').value;
    
    if (!responseText.trim()) {
      alert('Please share your thoughts before submitting.');
      return;
    }

    this.showLoading();

    try {
      const response = await fetch('/wheel_of_life/process_response', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          category_id: this.currentCategory,
          response_text: responseText
        })
      });

      const data = await response.json();

      if (data.success) {
        this.displayResults(data);
        
        // Play audio summary if available
        if (data.audio_url) {
          setTimeout(() => {
            this.playAudio(data.audio_url);
          }, 1000);
        }
      } else {
        alert('Error: ' + data.error);
      }
    } catch (error) {
      console.error('Error:', error);
      alert('An error occurred while processing your response.');
    } finally {
      this.hideLoading();
    }
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
                ${data.analysis.working_well.map(item => `<li>${item}</li>`).join('')}
              </ul>
            </div>
          </div>

          <div class="col-md-6">
            <div class="needs-improvement">
              <h5 class="text-warning">🎯 Areas for Growth</h5>
              <ul>
                ${data.analysis.needs_improvement.map(item => `<li>${item}</li>`).join('')}
              </ul>
            </div>
          </div>
        </div>

        ${data.goals.length > 0 ? this.renderGoals(data.goals) : ''}

        ${data.audio_url ? `
          <div class="audio-summary mt-4">
            <button class="btn btn-info play-audio-btn" data-audio-url="${data.audio_url}">
              🔊 Play Audio Summary
            </button>
          </div>
        ` : ''}
      </div>
    `;

    document.getElementById('results-container').innerHTML = resultsHtml;
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
    `;
  }

  playAudio(audioUrl) {
    const audio = new Audio(audioUrl);
    audio.play().catch(error => {
      console.error('Audio playback failed:', error);
    });
  }

  showLoading() {
    document.getElementById('submit-response').innerHTML = 'Analyzing... ⏳';
    document.getElementById('submit-response').disabled = true;
  }

  hideLoading() {
    document.getElementById('submit-response').innerHTML = 'Analyze My Response';
    document.getElementById('submit-response').disabled = false;
  }

  getCategoryData(categoryId) {
    // This would typically come from your Rails data
    // For now, return placeholder data
    return {
      name: 'Category Name',
      prompt: 'Category prompt here...'
    };
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  new WheelOfLifeInterface();
});