# UTMStack Quick Deployment Checklist

## Pre-Deployment
- [ ] Ubuntu 22.04 LTS with 4+ cores, 16GB+ RAM, 150GB+ storage
- [ ] Static IP address configured
- [ ] Docker Engine 20.10+ installed
- [ ] Docker Compose 2.0+ installed
- [ ] Node.js 18+ installed

## Critical Configuration Steps
- [ ] **Frontend Environment**: Set `SERVER_API_URL: 'http://localhost:8080/'` in `environment.prod.ts`
- [ ] **Angular Build**: Use `NODE_OPTIONS="--openssl-legacy-provider"` for npm build
- [ ] **Angular Config**: Set `optimization: false` and `buildOptimizer: false` in `angular.json`
- [ ] **TypeScript**: Use `target: "es2015"` and `module: "es2015"` in `tsconfig.json`
- [ ] **Scripts**: Only include `jquery.min.js` in angular.json scripts array

## Build Process
```bash
cd frontend
export NODE_OPTIONS="--openssl-legacy-provider"
npm install
npm run build
```

## Deployment
```bash
cd /opt/UTMStack
docker-compose up -d --build
```

## Verification
- [ ] Frontend accessible at `http://server-ip:3000`
- [ ] Backend API responding at `http://server-ip:8080/api/ping`
- [ ] Login form visible (not loading spinner)
- [ ] Can login with `admin` / `utmstack`

## Common Issues & Quick Fixes
- **White page**: Check frontend build and browser console
- **Export syntax errors**: Verify angular.json optimization settings
- **No login form**: Check SERVER_API_URL configuration
- **API errors**: Verify backend service is running

## Default Credentials
- **Username**: `admin`
- **Password**: `utmstack`

## Security (Post-Deployment)
- [ ] Change default admin password
- [ ] Configure firewall (ports 22, 80, 443, 3000, 8080)
- [ ] Set up SSL/HTTPS for production
- [ ] Configure log rotation
- [ ] Set up regular backups
