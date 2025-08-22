# Heroku Deployment Guide for Orgomojo

## Prerequisites

1. Install the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
2. Have a Heroku account

## Quick Deployment Steps

### 1. Create Heroku App
```bash
heroku create your-app-name
```

### 2. Add Required Addons
```bash
# PostgreSQL database
heroku addons:create heroku-postgresql:essential-0

# Redis for ActionCable (if using real-time features)
heroku addons:create heroku-redis:mini
```

### 3. Set Environment Variables
```bash
# Required for production
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)

# Optional: AI Services (app will work without these)
heroku config:set OPENAI_API_KEY=your_openai_api_key_here
heroku config:set GOOGLE_API_KEY=your_google_api_key_here

# Optional: Google OAuth (if using Google login)
heroku config:set GOOGLE_CLIENT_ID=your_google_client_id
heroku config:set GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### 4. Deploy
```bash
git push heroku main
```

### 5. Run Database Migrations
```bash
heroku run rails db:migrate
heroku run rails db:seed  # Optional: load initial data
```

### 6. Open Your App
```bash
heroku open
```

## Environment Variables

### Required
- `RAILS_MASTER_KEY` - Rails credentials key (auto-generated)

### Optional (app degrades gracefully without these)
- `OPENAI_API_KEY` - For AI text rewriting features
- `GOOGLE_API_KEY` - For Gemini AI services  
- `GOOGLE_CLIENT_ID` - For Google OAuth login
- `GOOGLE_CLIENT_SECRET` - For Google OAuth login

## Important Notes

1. **AI Features**: The app will work without API keys - AI features will simply be disabled
2. **Asset Precompilation**: Fixed to work without API keys present
3. **Database**: Uses PostgreSQL in production (configured automatically)
4. **Logs**: Check logs with `heroku logs --tail` if issues occur

## Troubleshooting

### Asset Precompilation Issues
If you encounter issues during deployment:
```bash
# Check build logs
heroku logs --tail --source build

# Manually precompile assets (shouldn't be needed)
heroku run rails assets:precompile
```

### Database Issues
```bash
# Reset database if needed
heroku pg:reset DATABASE_URL
heroku run rails db:migrate db:seed
```

### Check App Status
```bash
heroku ps
heroku logs --tail
```

## Scaling (Optional)

For production traffic:
```bash
# Scale web dynos
heroku ps:scale web=2

# Upgrade database
heroku addons:upgrade DATABASE_URL:standard-0
```
