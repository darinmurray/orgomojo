# db/seeds.rb
# Clear existing data
Pie.destroy_all

# Create sample pie
pie = Pie.create!(name: "Life Balance Wheel")

# Create slices with elements
health_slice = pie.slices.create!(name: "Health", color: "#90EE90")
health_slice.elements.create!([
  { name: "Exercise 3+ times per week", completed: true },
  { name: "Eat 5+ servings of fruits/vegetables daily", completed: true },
  { name: "Get 7-8 hours of sleep", completed: true },
  { name: "Regular medical checkups", completed: true },
  { name: "Maintain healthy weight", completed: true }
])

purpose_slice = pie.slices.create!(name: "Higher Purpose", color: "#CD5C5C")
purpose_slice.elements.create!([
  { name: "Clear personal mission statement", completed: true },
  { name: "Regular spiritual/meditation practice", completed: true },
  { name: "Volunteer or give back to community", completed: true },
  { name: "Feel connected to something greater", completed: true },
  { name: "Living according to core values", completed: false }
])

work_slice = pie.slices.create!(name: "Work/Mission", color: "#F0E68C")
work_slice.elements.create!([
  { name: "Enjoy my work most days", completed: true },
  { name: "Feel challenged and growing", completed: true },
  { name: "Good work-life balance", completed: true },
  { name: "Fair compensation", completed: true },
  { name: "Clear career path", completed: false }
])

relationship_slice = pie.slices.create!(name: "Relationships", color: "#87CEEB")
relationship_slice.elements.create!([
  { name: "Loving spouse", completed: true },
  { name: "Open communications both ways", completed: false },
  { name: "Feel like I'm treated fairly", completed: true },
  { name: "Regular date nights", completed: false },
  { name: "Give and receive adequate praise", completed: false }
])

wealth_slice = pie.slices.create!(name: "Wealth", color: "#DDA0DD")
wealth_slice.elements.create!([
  { name: "Emergency fund (3-6 months expenses)", completed: false },
  { name: "Saving for retirement", completed: true },
  { name: "No high-interest debt", completed: false },
  { name: "Clear financial goals", completed: true },
  { name: "Regular budget tracking", completed: false }
])

development_slice = pie.slices.create!(name: "Development", color: "#20B2AA")
development_slice.elements.create!([
  { name: "Learning new skills regularly", completed: false },
  { name: "Reading personal development books", completed: true },
  { name: "Seeking feedback and acting on it", completed: false },
  { name: "Setting and achieving goals", completed: false },
  { name: "Stepping outside comfort zone", completed: false }
])

puts "Created pie: #{pie.name} with #{pie.slices.count} slices"
pie.slices.each do |slice|
  puts "  #{slice.name}: #{slice.percentage}% (#{slice.elements.where(completed: true).count}/#{slice.elements.count} elements completed)"
end










# # db/seeds.rb
# # Clear existing data
# Pie.destroy_all

# # Create sample pie
# pie = Pie.create!(name: "Life Balance Wheel")

# pie.slices.create!([
#   { name: "Health", percentage: 100, color: "#90EE90" },
#   { name: "Higher Purpose", percentage: 90, color: "#CD5C5C" },
#   { name: "Work/Mission", percentage: 80, color: "#F0E68C" },
#   { name: "Relationships", percentage: 80, color: "#87CEEB" },
#   { name: "Wealth", percentage: 30, color: "#DDA0DD" },
#   { name: "Development", percentage: 10, color: "#20B2AA" }
# ])

# puts "Created pie: #{pie.name} with #{pie.slices.count} slices"