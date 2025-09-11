# Afeedi Deployment Guide

This guide provides comprehensive instructions for deploying the Afeedi browser-based streaming platform to various hosting providers.

## Prerequisites

- Flutter SDK (3.24.0 or later)
- Git repository access
- Environment variables configured
- Supabase project setup

## Environment Configuration

### 1. Create Environment File

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Update the following variables:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# OAuth Configuration
YOUTUBE_CLIENT_ID=your-youtube-client-id
INSTAGRAM_CLIENT_ID=your-instagram-client-id
TIKTOK_CLIENT_ID=your-tiktok-client-id
FACEBOOK_APP_ID=your-facebook-app-id

# Analytics
ANALYTICS_API_KEY=your-analytics-key
```

### 2. Build for Production

```bash
# Install dependencies
flutter pub get

# Build web version
flutter build web --release
```

## Deployment Options

### Option 1: Netlify Deployment

#### Automatic Deployment (Recommended)

1. **Connect Repository**
   - Go to [Netlify](https://netlify.com)
   - Click "New site from Git"
   - Connect your GitHub/GitLab repository

2. **Configure Build Settings**
   - Build command: `flutter build web --release`
   - Publish directory: `build/web`
   - The `netlify.toml` file will handle the rest

3. **Environment Variables**
   - Go to Site settings > Environment variables
   - Add all environment variables from your `.env` file

#### Manual Deployment

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Deploy
netlify deploy --prod --dir=build/web
```

### Option 2: Vercel Deployment

#### Automatic Deployment

1. **Connect Repository**
   - Go to [Vercel](https://vercel.com)
   - Import your Git repository
   - The `vercel.json` file will configure the build

2. **Environment Variables**
   - Add environment variables in Vercel dashboard
   - Go to Project Settings > Environment Variables

#### Manual Deployment

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy
vercel --prod
```

### Option 3: Firebase Hosting

#### Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init hosting
```

#### Deploy

```bash
# Build the project
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

### Option 4: GitHub Pages

#### Setup GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build web
      run: flutter build web --release --base-href "/afeedi/"
      
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      if: github.ref == 'refs/heads/main'
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./build/web
```

### Option 5: Custom Server (Docker)

#### Dockerfile

```dockerfile
FROM nginx:alpine

# Copy built web files
COPY build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

#### nginx.conf

```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
        
        # Security headers
        add_header X-Frame-Options "DENY";
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Content-Type-Options "nosniff";
        add_header Referrer-Policy "strict-origin-when-cross-origin";
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.youtube.com https://www.instagram.com https://www.tiktok.com https://www.facebook.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; media-src 'self' https:; frame-src 'self' https://www.youtube.com https://www.instagram.com https://www.tiktok.com https://www.facebook.com;";
        
        # Cache static assets
        location ~* \.(js|css|wasm)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

#### Deploy with Docker

```bash
# Build Docker image
docker build -t afeedi-web .

# Run container
docker run -p 80:80 afeedi-web
```

## Post-Deployment Configuration

### 1. Domain Setup

- Configure custom domain in hosting provider
- Set up SSL certificate (usually automatic)
- Update CORS settings in Supabase for your domain

### 2. OAuth Redirect URLs

Update OAuth app configurations with your deployment URL:

- **YouTube**: `https://yourdomain.com/auth/youtube/callback`
- **Instagram**: `https://yourdomain.com/auth/instagram/callback`
- **TikTok**: `https://yourdomain.com/auth/tiktok/callback`
- **Facebook**: `https://yourdomain.com/auth/facebook/callback`

### 3. Supabase Configuration

- Add your domain to allowed origins in Supabase dashboard
- Update RLS policies if needed
- Configure edge functions for your domain

### 4. Analytics Setup

- Configure analytics tracking for your domain
- Set up monitoring and error tracking
- Enable performance monitoring

## Performance Optimization

### 1. CDN Configuration

- Enable CDN for static assets
- Configure proper cache headers
- Use image optimization services

### 2. Monitoring

- Set up uptime monitoring
- Configure error tracking (Sentry, etc.)
- Monitor Core Web Vitals

### 3. SEO Optimization

- Configure meta tags in `web/index.html`
- Set up sitemap.xml
- Configure robots.txt

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Check Supabase CORS settings
   - Verify OAuth redirect URLs

2. **Build Failures**
   - Check Flutter version compatibility
   - Verify all dependencies are compatible with web

3. **Performance Issues**
   - Enable tree-shaking: `--tree-shake-icons`
   - Use `--split-debug-info` for smaller builds
   - Consider lazy loading for large components

### Debug Commands

```bash
# Check build size
flutter build web --analyze-size

# Profile build
flutter build web --profile

# Debug web build
flutter run -d chrome --debug
```

## Security Considerations

- Always use HTTPS in production
- Configure proper CSP headers
- Regularly update dependencies
- Monitor for security vulnerabilities
- Use environment variables for sensitive data
- Enable proper authentication and authorization

## Support

For deployment issues:

1. Check the deployment logs
2. Verify environment variables
3. Test locally with production build
4. Check hosting provider documentation
5. Review Supabase configuration

---

**Note**: This deployment guide covers the most common hosting scenarios. Choose the option that best fits your infrastructure and requirements.