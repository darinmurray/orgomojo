# Copilot Instructions for Orgomojo Codebase

Welcome to the Orgomojo codebase! This document provides essential guidance for AI coding agents to be productive in this project. It covers the architecture, workflows, conventions, and integration points specific to this application.

---

## Project Overview

Orgomojo is a Rails-based application designed to manage and visualize user data through interactive components like pies, slices, and core values. The application uses PostgreSQL as its database and integrates with external services like OpenAI and Google APIs.

### Key Components

1. **Models**
   - `Pie`, `Slice`, `CoreValue`, and `Element` are the primary models.
   - Relationships:
     - `Pie` has many `Slices`.
     - `Slice` has many `Elements`.
     - `User` has many `CoreValues` through a join table (`UserCoreValue`).

2. **Controllers**
   - Follow standard Rails conventions.
   - Example: `CoreValuesController` handles CRUD operations for core values.

3. **Views**
   - Use ERB templates for rendering HTML.
   - Stimulus controllers are used for interactive elements (e.g., inline editing in `core_values/index.html.erb`).

4. **JavaScript**
   - Stimulus is used for frontend interactivity.
   - Example: `core_values_controller.js` manages inline editing of core values.

5. **Database**
   - PostgreSQL is the database backend.
   - Uses ActiveRecord for ORM.

---

## Developer Workflows

### Setting Up the Project
1. Install dependencies:
   ```bash
   bundle install
   yarn install
   ```
2. Set up the database:
   ```bash
   rails db:create db:migrate db:seed
   ```
3. Start the server:
   ```bash
   rails server
   ```

### Running Tests
- Run all tests:
  ```bash
  rails test
  ```
- Run a specific test file:
  ```bash
  rails test test/models/pie_test.rb
  ```

### Debugging
- Use `byebug` for debugging Ruby code.
- Use browser developer tools for debugging JavaScript and Stimulus controllers.

---

## Project-Specific Conventions

1. **Stimulus Controllers**
   - Located in `app/javascript/controllers/`.
   - Follow the naming convention `<resource>_controller.js`.
   - Example: `core_values_controller.js` manages inline editing for core values.

2. **Database Migrations**
   - Use PostgreSQL-specific features like arrays (`t.column :examples, :string, array: true, default: []`).

3. **Error Handling**
   - Use Rails flash messages for user-facing errors.
   - Example: `redirect_to core_values_path, alert: 'Error updating core value.'`.

4. **Responsive Design**
   - Use CSS classes and media queries for responsiveness.
   - Example: The `core_values/index.html.erb` view adapts to different screen sizes.

---

## Integration Points

1. **External Services**
   - OpenAI: Used for AI-driven features.
   - Google APIs: Used for authentication and other integrations.

2. **Footer Links**
   - Add new links in `app/views/layouts/_footer.html.erb`.
   - Example: A link to the Core Values page.

---

## Key Files and Directories

- `app/models/`: Contains all ActiveRecord models.
- `app/controllers/`: Contains all Rails controllers.
- `app/views/`: Contains all ERB templates.
- `app/javascript/controllers/`: Contains Stimulus controllers.
- `config/routes.rb`: Defines application routes.
- `db/migrate/`: Contains database migrations.

---

Feel free to update this document as the project evolves!
