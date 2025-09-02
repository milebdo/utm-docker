# Building UTMStack from Source

This document describes how to build UTMStack from source code, including all prerequisites and configuration requirements.

## Prerequisites

### Required Software

- **Go**: Version 1.23 or later
- **Maven**: Version 3.3.9 or later  
- **Node.js**: Version 16.x or earlier (required for Angular 7 compatibility)
- **Python**: Version 3.x with pip
- **Git**: For cloning the repository

### System Requirements

- **Operating System**: Linux, macOS, or Windows
- **Memory**: Minimum 8GB RAM (16GB recommended)
- **Disk Space**: At least 10GB free space
- **Network**: Internet access for downloading dependencies

## Installation of Prerequisites

### Go Installation

```bash
# Download and install Go from https://golang.org/dl/
# Or use package manager:

# Ubuntu/Debian
sudo apt update
sudo apt install golang-go

# macOS (using Homebrew)
brew install go

# Verify installation
go version
```

### Maven Installation

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install maven

# macOS (using Homebrew)
brew install maven

# Verify installation
mvn --version
```

### Node.js Installation

**IMPORTANT**: UTMStack uses Angular 7, which requires Node.js 16.x or earlier for compatibility.

```bash
# Using Node Version Manager (nvm) - RECOMMENDED
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc  # or source ~/.zshrc for zsh

# Install and use Node.js 16.x
nvm install 16.20.2
nvm use 16.20.2
nvm alias default 16.20.2

# Verify installation
node --version  # Should show v16.20.2
npm --version
```

**Alternative installation methods:**

```bash
# Ubuntu/Debian (NodeSource repository)
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS (using Homebrew with specific version)
brew install node@16
brew link node@16 --force
```

### Python Installation

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-pip

# macOS (using Homebrew)
brew install python3

# Verify installation
python3 --version
pip3 --version
```

## Repository Access

### UTMStack Private Maven Repository

The backend requires access to UTMStack's private Maven repository hosted on GitHub Packages. You need:

1. **GitHub Personal Access Token** with `read:packages` scope
2. **Proper Maven configuration** in `backend/settings.xml`

#### Setting up GitHub Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Generate a new token with `read:packages` permission
3. Copy the token

#### Configure Maven Authentication

```bash
# Set the environment variable
export MAVEN_TK=your_github_token_here

# Or add to your shell profile (~/.bashrc, ~/.zshrc, etc.)
echo 'export MAVEN_TK=your_github_token_here' >> ~/.bashrc
source ~/.bashrc
```

**Note**: The `MAVEN_TK` environment variable is used by the Maven settings.xml file to authenticate with GitHub Packages.

## Building UTMStack

### Quick Build

```bash
# Clone the repository
git clone https://github.com/utmstack/UTMStack.git
cd UTMStack

# Set your GitHub token for Maven access
export MAVEN_TK=your_github_token_here

# Run the build script
./build.sh
```

### Manual Build Steps

If you prefer to build components individually:

#### 1. Build Go Components

```bash
# Build all Go components
cd agent && go build -o ../bin/utmstack-agent . && cd ..
cd agent-manager && go build -o ../bin/utmstack-agent-manager . && cd ..
cd correlation && go build -o ../bin/utmstack-correlation . && cd ..
cd installer && go build -o ../bin/utmstack-installer . && cd ..
cd aws && go build -o ../bin/utmstack-aws . && cd ..
cd bitdefender && go build -o ../bin/utmstack-bitdefender . && cd ..
cd office365 && go build -o ../bin/utmstack-office365 . && cd ..
cd sophos && go build -o ../bin/utmstack-sophos . && cd ..
cd soc-ai && go build -o ../bin/utmstack-soc-ai . && cd ..
cd log-auth-proxy && go build -o ../bin/utmstack-log-auth-proxy . && cd ..
```

#### 2. Build Java Backend

```bash
cd backend

# Build with UTMStack Maven configuration
mvn clean install -DskipTests --settings settings.xml

cd ..
```

#### 3. Build Frontend

```bash
cd frontend

# Install dependencies
npm install

# Build the application
npm run build

cd ..
```

#### 4. Install Python Dependencies

```bash
cd mutate

# Install requirements
pip3 install -r requirements.txt

cd ..
```

## Build Output

After successful build, you'll find the compiled binaries in the `bin/` directory:

- `utmstack-agent` - UTMStack agent binary
- `utmstack-agent-manager` - Agent management service
- `utmstack-correlation` - Correlation engine
- `utmstack-installer` - Installation utility
- `utmstack-aws` - AWS integration service
- `utmstack-bitdefender` - Bitdefender integration
- `utmstack-office365` - Office 365 integration
- `utmstack-sophos` - Sophos integration
- `utmstack-soc-ai` - SOC AI service
- `utmstack-log-auth-proxy` - Log authentication proxy

## Troubleshooting

### Common Issues

#### Node.js Version Incompatibility

**Error**: "Node.js version X.X.X is not compatible with Angular 7"

**Solution**: Install Node.js 16.x or earlier
```bash
nvm install 16.20.2
nvm use 16.20.2
```

#### Maven Authentication Failures

**Error**: "401 Unauthorized" or "Authentication failed"

**Solution**: Ensure MAVEN_TK environment variable is set
```bash
export MAVEN_TK=your_github_token_here
echo $MAVEN_TK  # Verify it's set
```

#### Missing Dependencies

**Error**: "Could not resolve dependencies"

**Solution**: Check network connectivity and GitHub token permissions
```bash
# Test GitHub API access
curl -H "Authorization: token $MAVEN_TK" https://api.github.com/user

# Verify Maven settings
mvn help:effective-settings
```

#### Go Module Issues

**Error**: "go: module lookup disabled"

**Solution**: Enable Go modules
```bash
export GO111MODULE=on
go mod tidy
```

### Getting Help

If you encounter build issues:

1. Check the error messages in the build output
2. Verify all prerequisites are installed with correct versions
3. Ensure your GitHub token has proper permissions
4. Check network connectivity to GitHub Packages
5. Open an issue on the UTMStack GitHub repository

## Development

### Frontend Development

For frontend development, use the development server:

```bash
cd frontend
npm start
```

The application will be available at `http://localhost:4200`

### Backend Development

For backend development, you can run the application directly:

```bash
cd backend
mvn spring-boot:run
```

### Go Components Development

For Go components, you can use hot reloading:

```bash
# Install air for hot reloading
go install github.com/cosmtrek/air@latest

# Run with hot reload
cd agent
air
```

## Contributing

When contributing to UTMStack:

1. Ensure your development environment matches the build requirements
2. Test your changes with the build script
3. Follow the project's coding standards
4. Update documentation as needed

For more information, see [CONTRIBUTING.md](CONTRIBUTING.md).
