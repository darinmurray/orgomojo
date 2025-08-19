# app/helpers/pie_chart_helper.rb
module PieChartHelper
  def radial_pie_chart(pie, options = {})
    size = options[:size] || 400
    center = size / 2
    outer_radius = center - 20
    label_radius = outer_radius + 12
    label_radius_offset_horizontal = -4
    label_radius_offset_vertical = -1
    pinwheel_effect = options[:pinwheel] || false
    show_curved_labels = options[:curved_labels] || false

    # Choose viewBox based on curved label option
    view_box = show_curved_labels ? "-10 -10 #{size + 20} #{size + 20}" : "15 15 #{size - 30} #{size - 30}"

    content_tag :svg, width: size, height: size, class: "radial-pie-chart", viewBox: view_box do
      content = ""

      # Add SVG definitions for pinwheel effect AND text paths
      content += content_tag :defs do
        defs_content = ""

        # Add pinwheel effects if enabled
        if pinwheel_effect
          # Drop shadow filter
          shadow_filter = content_tag :filter, id: "pinwheel-shadow", x: "-20%", y: "-20%", width: "140%", height: "140%" do
            content_tag(:feGaussianBlur, nil, in: "SourceAlpha", stdDeviation: "3") +
            content_tag(:feOffset, nil, dx: "2", dy: "2", result: "offset") +
            content_tag(:feFlood, nil, "flood-color": "#000000", "flood-opacity": "0.3") +
            content_tag(:feComposite, nil, in2: "offset", operator: "in") +
            content_tag(:feMerge, nil) do
              content_tag(:feMergeNode, nil) +
              content_tag(:feMergeNode, nil, in: "SourceGraphic")
            end
          end

          # Radial gradients for each slice to create depth
          gradients = pie.slices.map.with_index do |slice, index|
            # Create a lighter version of the slice color for the gradient
            lighter_color = lighten_color(slice.color, 0.3)
            darker_color = darken_color(slice.color, 0.15)

            content_tag :radialGradient, id: "gradient-#{index}", cx: "40%", cy: "40%", r: "80%" do
              content_tag(:stop, nil, offset: "0%", "stop-color": lighter_color) +
              # DTM Change this to 60% to match the original
              content_tag(:stop, nil, offset: "01%", "stop-color": slice.color) +
              content_tag(:stop, nil, offset: "100%", "stop-color": darker_color)
            end
          end.join.html_safe

          defs_content += (shadow_filter + gradients).html_safe
        end

        # Create text paths for curved labels (only if enabled)
        if show_curved_labels
          text_paths = pie.slices.map.with_index do |slice, index|
            angle_per_slice = 360.0 / pie.slices.count
            start_angle = index * angle_per_slice - 90 # Start from top
            end_angle = start_angle + angle_per_slice

            create_text_path(center + label_radius_offset_horizontal, center + label_radius_offset_vertical, label_radius, start_angle, end_angle, index)
          end.join.html_safe

          defs_content += text_paths
        end

        defs_content.html_safe
      end

      # Create clickable slices wrapped in anchor tags
      slices = pie.slices.map.with_index do |slice, index|
        angle_per_slice = 360.0 / pie.slices.count
        start_angle = index * angle_per_slice - 90 # Start from top

        slice_path = create_slice_path(center, start_angle, angle_per_slice, slice.percentage, size)

        # Only render slices with some percentage
        if slice.percentage > 0
          slice_attributes = {
            d: slice_path,
            fill: pinwheel_effect ? "url(#gradient-#{index})" : slice.color,
            stroke: "#fff",
            "stroke-width": 0, # Use 0 for no stroke in pinwheel effect
            class: "pie-slice clickable-slice",
            "data-slice": slice.name,
            "data-percentage": slice.percentage,
            "data-slice-id": slice.id,
            style: "cursor: pointer; transition: opacity 0.2s ease;"
          }

          slice_attributes[:filter] = "url(#pinwheel-shadow)" if pinwheel_effect

          content_tag :path, nil, slice_attributes
        else
          ""
        end
      end.join

      # Add curved text labels (only if enabled)
      curved_labels = if show_curved_labels
        pie.slices.map.with_index do |slice, index|
          content_tag :text, class: "slice-label" do
            content_tag :textPath, slice.name, href: "#textPath#{index}", startOffset: "50%", "text-anchor": "middle"
          end
        end.join.html_safe
      else
        ""
      end

      # Add divider lines between slices
      divider_lines = pie.slices.map.with_index do |slice, index|
        angle_per_slice = 360.0 / pie.slices.count
        angle = index * angle_per_slice - 90 # Start from top

        # Convert to radians
        angle_rad = angle * Math::PI / 180

        # Calculate line endpoints (from center to outer edge)
        x1 = center
        y1 = center
        x2 = center + outer_radius * Math.cos(angle_rad)
        y2 = center + outer_radius * Math.sin(angle_rad)

        content_tag :line, nil,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          stroke: "var(--pie-spoke)",
          "stroke-width": show_curved_labels ? 2 : 1,
          class: "pie-divider"
      end.join

      # Add the outer circumference circle
      outer_circle = content_tag :circle, nil,
        cx: center,
        cy: center,
        r: outer_radius,
        fill: "none",
        stroke: "var(--pie-circumference)",
        "stroke-width": show_curved_labels ? 2 : 1,
        class: "pie-outer-border"

      # Add slice outlines for all slices (show on hover)
      slice_outlines = pie.slices.map.with_index do |slice, index|
        angle_per_slice = 360.0 / pie.slices.count
        start_angle = index * angle_per_slice - 90 # Start from top

        # Create the full outline path (always goes to outer_radius)
        outline_path = create_full_slice_outline_path(center, start_angle, angle_per_slice, outer_radius)

        content_tag :path, nil,
          d: outline_path,
          fill: "none",
          stroke: "#cccccc",
          "stroke-width": 2,
          class: "slice-outline",
          "data-slice-id": slice.id,
          style: "opacity: 0; transition: all 0.3s ease; cursor: pointer; pointer-events: none;"
      end.join

      # Add invisible hover areas for full slice regions
      hover_areas = pie.slices.map.with_index do |slice, index|
        angle_per_slice = 360.0 / pie.slices.count
        start_angle = index * angle_per_slice - 90 # Start from top

        # Create the full slice path for hover detection
        hover_path = create_full_slice_outline_path(center, start_angle, angle_per_slice, outer_radius)

        content_tag :path, nil,
          d: hover_path,
          fill: "transparent",
          stroke: "none",
          class: "slice-hover-area",
          "data-slice-id": slice.id,
          style: "cursor: pointer;"
      end.join

      # Add JavaScript for click handling and outline hover effects
      javascript = content_tag :script do
        "
        document.addEventListener('DOMContentLoaded', function() {
          // Handle hover areas (invisible full slice regions)
          document.querySelectorAll('.slice-hover-area').forEach(function(hoverArea) {
            hoverArea.addEventListener('click', function() {
              const sliceId = this.dataset.sliceId;
              const pieId = #{pie.id};
              window.location.href = '/pies/' + pieId + '/slices/' + sliceId;
            });

            hoverArea.addEventListener('mouseenter', function() {
              const sliceId = this.dataset.sliceId;
              // Dim the corresponding slice
              const slice = document.querySelector('.clickable-slice[data-slice-id=\"' + sliceId + '\"]');
              if (slice) {
                slice.style.opacity = '0.8';
              }
              // Show corresponding outline
              const outline = document.querySelector('.slice-outline[data-slice-id=\"' + sliceId + '\"]');
              if (outline) {
                outline.style.opacity = '1';
                outline.style.stroke = 'var(--focus)';
                outline.style.strokeWidth = '1';
              }
            });

            hoverArea.addEventListener('mouseleave', function() {
              const sliceId = this.dataset.sliceId;
              // Restore slice opacity
              const slice = document.querySelector('.clickable-slice[data-slice-id=\"' + sliceId + '\"]');
              if (slice) {
                slice.style.opacity = '1';
              }
              // Hide corresponding outline
              const outline = document.querySelector('.slice-outline[data-slice-id=\"' + sliceId + '\"]');
              if (outline) {
                outline.style.opacity = '0';
                outline.style.stroke = '#cccccc';
                outline.style.strokeWidth = '1';
              }
            });
          });

          // Handle slice clicks (keep for backward compatibility)
          document.querySelectorAll('.clickable-slice').forEach(function(slice) {
            slice.addEventListener('click', function() {
              const sliceId = this.dataset.sliceId;
              const pieId = #{pie.id};
              window.location.href = '/pies/' + pieId + '/slices/' + sliceId;
            });

            // Add hover effects for slices
            slice.addEventListener('mouseenter', function() {
              this.style.opacity = '0.8';
              // Show corresponding outline if it exists
              const sliceId = this.dataset.sliceId;
              const outline = document.querySelector('.slice-outline[data-slice-id=\"' + sliceId + '\"]');
              if (outline) {
                outline.style.opacity = '1';
                outline.style.stroke = 'var(--focus)';
                outline.style.strokeWidth = '1';
              }
            });

            slice.addEventListener('mouseleave', function() {
              this.style.opacity = '1';
              // Hide corresponding outline
              const sliceId = this.dataset.sliceId;
              const outline = document.querySelector('.slice-outline[data-slice-id=\"' + sliceId + '\"]');
              if (outline) {
                outline.style.opacity = '0';
                outline.style.stroke = '#cccccc';
                outline.style.strokeWidth = '1';
              }
            });
          });
        });
        ".html_safe
      end

      (content + slices + curved_labels + divider_lines + outer_circle + slice_outlines + hover_areas + javascript).html_safe
    end
  end

  private

  def create_slice_path(center, start_angle, slice_angle, percentage, size)
    outer_radius = center - 20

    # Calculate the radius based on percentage (from center outward)
    current_radius = outer_radius * (percentage / 100.0)

    # Convert to radians
    start_rad = start_angle * Math::PI / 180
    end_rad = (start_angle + slice_angle) * Math::PI / 180

    # Calculate arc points - start from center
    x2 = center + current_radius * Math.cos(start_rad)
    y2 = center + current_radius * Math.sin(start_rad)
    x3 = center + current_radius * Math.cos(end_rad)
    y3 = center + current_radius * Math.sin(end_rad)

    large_arc = slice_angle > 180 ? 1 : 0

    # Create the path - ensure we always have a valid path for any percentage > 0
    "M #{center},#{center} L #{x2},#{y2} A #{current_radius},#{current_radius} 0 #{large_arc},1 #{x3},#{y3} Z"
  end

  def create_full_slice_outline_path(center, start_angle, slice_angle, outer_radius)
    # Convert to radians
    start_rad = start_angle * Math::PI / 180
    end_rad = (start_angle + slice_angle) * Math::PI / 180

    # Calculate arc points at full outer radius
    x2 = center + outer_radius * Math.cos(start_rad)
    y2 = center + outer_radius * Math.sin(start_rad)
    x3 = center + outer_radius * Math.cos(end_rad)
    y3 = center + outer_radius * Math.sin(end_rad)

    large_arc = slice_angle > 180 ? 1 : 0

    # Create the outline path - from center to edge, arc around, back to center
    "M #{center},#{center} L #{x2},#{y2} A #{outer_radius},#{outer_radius} 0 #{large_arc},1 #{x3},#{y3} Z"
  end

  def create_text_path(center_x, center_y, radius, start_angle, end_angle, index)
    # Add padding to prevent text from going too close to slice edges
    padding = 3
    text_start_angle = start_angle + padding
    text_end_angle = end_angle - padding

    # Convert to radians
    start_rad = text_start_angle * Math::PI / 180
    end_rad = text_end_angle * Math::PI / 180

    # Calculate arc points using separate x and y centers
    start_x = center_x + radius * Math.cos(start_rad)
    start_y = center_y + radius * Math.sin(start_rad)
    end_x = center_x + radius * Math.cos(end_rad)
    end_y = center_y + radius * Math.sin(end_rad)

    # Determine if this is a large arc
    arc_angle = text_end_angle - text_start_angle
    large_arc = arc_angle > 180 ? 1 : 0

    # Check if text would be upside down - adjust for your coordinate system
    mid_angle = (start_angle + end_angle) / 2
    # Since start_angle can be negative (starts at -90), normalize properly
    normalized_mid = ((mid_angle % 360) + 360) % 360
    upside_down = normalized_mid > 135 && normalized_mid < 225

    # Create path - reverse direction for upside-down text
    if upside_down
      path_data = "M #{end_x},#{end_y} A #{radius},#{radius} 0 #{large_arc},0 #{start_x},#{start_y}"
    else
      path_data = "M #{start_x},#{start_y} A #{radius},#{radius} 0 #{large_arc},1 #{end_x},#{end_y}"
    end

    content_tag :path, nil, id: "textPath#{index}", d: path_data, fill: "none", stroke: "none"
  end

  def lighten_color(hex_color, amount)
    # Remove # if present
    hex = hex_color.gsub("#", "")

    # Convert to RGB
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)

    # Lighten
    r = [ (r + (255 - r) * amount).round, 255 ].min
    g = [ (g + (255 - g) * amount).round, 255 ].min
    b = [ (b + (255 - b) * amount).round, 255 ].min

    "#%02x%02x%02x" % [ r, g, b ]
  end

  def darken_color(hex_color, amount)
    # Remove # if present
    hex = hex_color.gsub("#", "")

    # Convert to RGB
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)

    # Darken
    r = [ (r * (1 - amount)).round, 0 ].max
    g = [ (g * (1 - amount)).round, 0 ].max
    b = [ (b * (1 - amount)).round, 0 ].max

    "#%02x%02x%02x" % [ r, g, b ]
  end
end
