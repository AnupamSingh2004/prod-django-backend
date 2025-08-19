# Django Backend with Azure PostgreSQL and Docker

A production-ready Django backend application configured to work with Azure PostgreSQL and deployed using Docker.

## 🏗️ Project Structure

```
DeployBackend/
├── myproject/              # Django project settings
│   ├── __init__.py
│   ├── settings.py         # Django settings with Azure PostgreSQL config
│   ├── urls.py            # URL routing
│   └── wsgi.py            # WSGI application
├── myapp/                 # Django application
│   ├── models.py          # Database models
│   ├── views.py           # API views
│   ├── urls.py            # App URLs
│   └── ...
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker configuration
├── docker-compose.yml    # Docker Compose for local development
├── .env                  # Environment variables
├── setup_azure_db.sh     # Azure PostgreSQL setup script
└── README.md             # This file
```

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Docker and Docker Compose
- Azure CLI (for PostgreSQL setup)
- Azure PostgreSQL Flexible Server
- Git

### 1. Clone and Setup

```bash
git clone <your-repo>
cd DeployBackend
```

### 2. Create Azure PostgreSQL Database

**Option A: Automated Setup (Recommended)**
```bash
# Make sure you're logged into Azure CLI
az login

# Run the automated setup script
./create_azure_postgres.sh
```

**Option B: Manual Setup**
```bash
# View manual steps
./azure_postgres_manual_steps.sh

# Or follow these commands:
az login
az group create --name django-backend-rg --location "East US"
az postgres flexible-server create \
  --resource-group django-backend-rg \
  --name your-postgres-server \
  --location "East US" \
  --admin-user postgres \
  --admin-password "YourSecurePassword123!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 15 \
  --public-access 0.0.0.0-255.255.255.255

az postgres flexible-server db create \
  --resource-group django-backend-rg \
  --server-name your-postgres-server \
  --database-name django_db
```

### 3. Configure Environment Variables

Update `.env` file with your Azure PostgreSQL details:

```env
SECRET_KEY=your-super-secret-key-here
DEBUG=False
DATABASE_URL=postgresql://postgres:YourPassword123!@your-server-name.postgres.database.azure.com:5432/django_db?sslmode=require
```

### 4. Test Database Connection

```bash
# Test Azure PostgreSQL connection
./test_azure_postgres.sh
```

### 5. Run with Docker

```bash
# Build and run with Azure PostgreSQL
docker-compose up --build

# Access the application
curl http://localhost:8000/
curl http://localhost:8000/health/
```

## 🔧 Configuration

### Environment Variables

Update `.env` file with your configuration:

```env
SECRET_KEY=your-super-secret-key-here
DEBUG=False
DATABASE_URL=postgresql://username:password@your-azure-postgres-server.postgres.database.azure.com:5432/your-database-name?sslmode=require
```

### Azure PostgreSQL Setup

1. Create an Azure PostgreSQL server
2. Configure firewall rules to allow your IP
3. Create a database
4. Update connection string in `.env`

## 📦 Docker Deployment

### Build Image

```bash
docker build -t django-backend .
```

### Run Container

```bash
docker run -p 8000:8000 --env-file .env django-backend
```

## 🚀 Deploy to Render

### Step 1: Prepare Repository

1. **Push to GitHub**:
   ```bash
   git init
   git add .
   git commit -m "Initial Django backend setup"
   git branch -M main
   git remote add origin https://github.com/your-username/your-repo.git
   git push -u origin main
   ```

### Step 2: Create Render Account

1. Go to [render.com](https://render.com)
2. Sign up with GitHub
3. Connect your GitHub account

### Step 3: Deploy Web Service

1. **Create New Web Service**:
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Select the repository with your Django app

2. **Configure Service**:
   ```
   Name: django-backend
   Environment: Docker
   Region: Choose closest to your users
   Branch: main
   ```

3. **Environment Variables** (Add in Render dashboard):
   ```
   SECRET_KEY=your-production-secret-key
   DEBUG=False
   DATABASE_URL=postgresql://username:password@your-azure-postgres-server.postgres.database.azure.com:5432/your-database-name?sslmode=require
   ALLOWED_HOSTS=your-app-name.onrender.com
   ```

4. **Advanced Settings**:
   ```
   Dockerfile Path: ./Dockerfile
   Docker Context: .
   ```

### Step 4: Azure PostgreSQL Configuration

1. **Create Azure PostgreSQL Server using our script**:
   ```bash
   # Automated setup (recommended)
   ./create_azure_postgres.sh
   
   # Or manual setup
   ./azure_postgres_manual_steps.sh
   ```

2. **Alternative: Using Azure CLI manually**:
   ```bash
   # Create resource group
   az group create --name django-backend-rg --location "Central India"
   
   # Create PostgreSQL server
   az postgres flexible-server create \
     --resource-group django-backend-rg \
     --name your-postgres-server \
     --location "Central India" \
     --admin-user postgres \
     --admin-password "YourSecurePassword123!" \
     --sku-name Standard_B1ms \
     --tier Burstable \
     --storage-size 32 \
     --version 15 \
     --public-access 0.0.0.0-255.255.255.255
   
   # Create database
   az postgres flexible-server db create \
     --resource-group django-backend-rg \
     --server-name your-postgres-server \
     --database-name django_db
   
   # Configure firewall
   az postgres flexible-server firewall-rule create \
     --resource-group django-backend-rg \
     --name your-postgres-server \
     --rule-name "AllowAzureServices" \
     --start-ip-address 0.0.0.0 \
     --end-ip-address 0.0.0.0
   ```

3. **Test your connection**:
   ```bash
   ./test_azure_postgres.sh
   ```

4. **Cost Management**:
   - Standard_B1ms: ~$15-25/month
   - You can scale up/down as needed
   - Delete resources when not needed: `az group delete --name django-backend-rg`

### Step 5: Deploy

1. Click "Create Web Service"
2. Render will automatically:
   - Clone your repository
   - Build the Docker image
   - Deploy the application
   - Provide a public URL

### Step 6: Post-Deployment

1. **Run Migrations** (via Render Shell):
   ```bash
   python manage.py migrate
   python manage.py collectstatic --noinput
   ```

2. **Create Superuser** (optional):
   ```bash
   python manage.py createsuperuser
   ```

3. **Test Endpoints**:
   ```bash
   curl https://your-app-name.onrender.com/
   curl https://your-app-name.onrender.com/health/
   ```

## 🔍 API Endpoints

- `GET /` - Welcome message
- `GET /health/` - Health check with database status
- `GET /admin/` - Django admin interface

## 📊 Features

- ✅ Django 4.2 with Azure PostgreSQL
- ✅ Docker containerization
- ✅ Production-ready settings
- ✅ CORS enabled
- ✅ Static files handling with WhiteNoise
- ✅ Health check endpoint
- ✅ Database logging
- ✅ Security middleware
- ✅ Environment-based configuration

## 🛠️ Development

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Start development server
python manage.py runserver
```

### Docker Development

```bash
# Development with live reload
docker-compose up

# Rebuild after changes
docker-compose up --build
```

## 🔒 Security Considerations

- Use strong SECRET_KEY in production
- Set DEBUG=False in production
- Configure ALLOWED_HOSTS properly
- Use environment variables for sensitive data
- Enable SSL for Azure PostgreSQL
- Regular security updates

## 📝 Monitoring

- Health check: `/health/`
- Admin interface: `/admin/`
- Database logs in `ApiLog` model
- Health status in `HealthStatus` model

## 🆘 Troubleshooting

### Database Connection Issues

1. Check Azure PostgreSQL firewall rules
2. Verify connection string format
3. Ensure SSL is enabled
4. Check credentials and database name

### Render Deployment Issues

1. Check build logs in Render dashboard
2. Verify environment variables
3. Ensure Dockerfile is correct
4. Check for port conflicts

### Common Commands

```bash
# Check database connection
python manage.py dbshell

# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic

# Create superuser
python manage.py createsuperuser
```
