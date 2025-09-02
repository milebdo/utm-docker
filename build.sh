#!/bin/bash
set -e

echo "Building UTMStack from source..."

# Create bin directory if it doesn't exist
mkdir -p bin

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if directory exists
dir_exists() {
    [ -d "$1" ]
}

# Check prerequisites
echo "Checking prerequisites..."

if ! command_exists go; then
    echo "Error: Go is not installed. Please install Go 1.23+ first."
    exit 1
fi

if ! command_exists mvn; then
    echo "Error: Maven is not installed. Please install Maven 3.3.9+ first."
    exit 1
fi

if ! command_exists npm; then
    echo "Error: Node.js/npm is not installed. Please install Node.js 16.x or earlier for Angular 7 compatibility."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
GO_MAJOR=$(echo $GO_VERSION | cut -d. -f1)
GO_MINOR=$(echo $GO_VERSION | cut -d. -f2)

if [ "$GO_MAJOR" -lt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -lt 23 ]); then
    echo "Error: Go version $GO_VERSION is too old. Please install Go 1.23+ first."
    exit 1
fi

# Check Node.js version for Angular 7 compatibility
NODE_VERSION=$(node --version | sed 's/v//')
NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)
NODE_MINOR=$(echo $NODE_VERSION | cut -d. -f2)

if [ "$NODE_MAJOR" -gt 16 ] || ([ "$NODE_MAJOR" -eq 16 ] && [ "$NODE_MINOR" -gt 20 ]); then
    echo "Error: Node.js version $NODE_VERSION is not compatible with Angular 7"
    echo "Angular 7 requires Node.js 8.x-16.x (preferably 16.x)"
    echo "Please install Node.js 16.x or earlier for compatibility"
    echo ""
    echo "You can use nvm to install the correct version:"
    echo "  nvm install 16.20.2"
    echo "  nvm use 16.20.2"
    exit 1
fi

echo "Go version: $GO_VERSION"
echo "Maven version: $(mvn --version | head -n1)"
echo "Node version: $NODE_VERSION (✓ Compatible with Angular 7)"
echo "NPM version: $(npm --version)"

# Build Go components
echo "Building Go components..."

# Function to build Go component
build_go_component() {
    local component=$1
    local binary_name=$2
    
    if dir_exists "$component"; then
        echo "Building $component..."
        cd "$component"
        if [ -f "go.mod" ]; then
            go mod tidy
            go build -o "../bin/$binary_name" .
            echo "✓ Built $binary_name"
        else
            echo "⚠ Skipping $component (no go.mod found)"
        fi
        cd ..
    else
        echo "⚠ Skipping $component (directory not found)"
    fi
}

build_go_component "agent" "utmstack-agent"
build_go_component "agent-manager" "utmstack-agent-manager"
build_go_component "correlation" "utmstack-correlation"
build_go_component "installer" "utmstack-installer"
build_go_component "aws" "utmstack-aws"
build_go_component "bitdefender" "utmstack-bitdefender"
build_go_component "office365" "utmstack-office365"
build_go_component "sophos" "utmstack-sophos"
build_go_component "soc-ai" "utmstack-soc-ai"
build_go_component "log-auth-proxy" "utmstack-log-auth-proxy"

# Build Java backend
echo "Building Java backend..."
if dir_exists "backend"; then
    cd backend
    
    # Check if Maven settings.xml exists and configure for UTMStack repository
    if [ -f "settings.xml" ]; then
        echo "Using UTMStack Maven configuration..."
        
        # Check if MAVEN_TK environment variable is set for private repository access
        if [ -z "$MAVEN_TK" ]; then
            echo "⚠ Warning: MAVEN_TK environment variable not set"
            echo "   This may cause authentication issues with UTMStack's private Maven repository"
            echo "   Set MAVEN_TK with your GitHub token: export MAVEN_TK=your_token_here"
        fi
        
        echo "Building with Maven using UTMStack configuration..."
        if mvn clean install -DskipTests --settings settings.xml; then
            echo "✓ Built Java backend"
        else
            echo "⚠ Java backend build failed"
            echo "   This may be due to:"
            echo "   - Missing MAVEN_TK environment variable for private repository access"
            echo "   - Network connectivity issues to GitHub Packages"
            echo "   - Missing dependencies in UTMStack's private repository"
            echo ""
            echo "To fix authentication issues:"
            echo "   export MAVEN_TK=your_github_token_here"
            echo "   ./build.sh"
        fi
    else
        echo "⚠ Warning: No settings.xml found in backend directory"
        echo "   Building with default Maven configuration (may fail due to missing dependencies)"
        
        if mvn clean install -DskipTests; then
            echo "✓ Built Java backend"
        else
            echo "⚠ Java backend build failed (missing UTMStack dependencies)"
            echo "   The backend requires UTMStack-specific dependencies from private repositories"
            echo "   Please ensure settings.xml is present and MAVEN_TK is set"
        fi
    fi
    cd ..
else
    echo "⚠ Skipping backend (directory not found)"
fi

# Build frontend
echo "Building frontend..."
if dir_exists "frontend"; then
    cd frontend
    if [ -f "package.json" ]; then
        echo "Installing npm dependencies..."
        
        # Node.js version already checked above, so we can proceed with confidence
        if npm install; then
            echo "✓ Installed npm dependencies"
            
            echo "Building frontend..."
            if npm run build; then
                echo "✓ Built frontend"
            else
                echo "⚠ Frontend build failed"
                echo "   This may be due to dependency issues or build configuration problems"
                echo "   Check the error output above for specific issues"
            fi
        else
            echo "⚠ Frontend dependency installation failed"
            echo "   Check the error output above for specific issues"
        fi
    else
        echo "⚠ Skipping frontend (no package.json found)"
    fi
    cd ..
else
    echo "⚠ Skipping frontend (directory not found)"
fi

# Install Python dependencies
echo "Installing Python dependencies..."
if dir_exists "mutate"; then
    cd mutate
    if [ -f "requirements.txt" ]; then
        if command_exists pip; then
            pip install -r requirements.txt
            echo "✓ Installed Python dependencies"
        elif command_exists pip3; then
            pip3 install -r requirements.txt
            echo "✓ Installed Python dependencies"
        else
            echo "⚠ Skipping Python dependencies (pip not found)"
        fi
    else
        echo "⚠ Skipping Python dependencies (no requirements.txt found)"
    fi
    cd ..
else
    echo "⚠ Skipping Python dependencies (directory not found)"
fi

echo "Build complete! Binaries are in the 'bin' directory."
echo ""
echo "Built components:"
ls -la bin/ 2>/dev/null || echo "No binaries were built"

# Ubuntu Server deployment section
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        echo ""
        echo "=========================================="
        echo "UBUNTU SERVER DEPLOYMENT INSTRUCTIONS"
        echo "=========================================="
        echo ""
        echo "Your UTMStack has been built successfully!"
        echo "To deploy on Ubuntu Server, follow these steps:"
        echo ""
        echo "1. Copy binaries to system directories:"
        echo "   sudo cp bin/* /usr/local/bin/"
        echo "   sudo chmod +x /usr/local/bin/utmstack-*"
        echo ""
        echo "2. Create systemd service files:"
        echo "   sudo mkdir -p /etc/systemd/system"
        echo ""
        echo "3. Start UTMStack services:"
        echo "   sudo systemctl daemon-reload"
        echo "   sudo systemctl enable utmstack-agent"
        echo "   sudo systemctl enable utmstack-agent-manager"
        echo "   sudo systemctl start utmstack-agent"
        echo "   sudo systemctl start utmstack-agent-manager"
        echo ""
        echo "4. Check service status:"
        echo "   sudo systemctl status utmstack-*"
        echo ""
        echo "5. View logs:"
        echo "   sudo journalctl -u utmstack-agent -f"
        echo "   sudo journalctl -u utmstack-agent-manager -f"
        echo ""
        echo "6. Access UTMStack web interface:"
        echo "   http://your-server-ip:8080"
        echo ""
        echo "7. Configure firewall (already done during installation):"
        echo "   sudo ufw status"
        echo ""
        echo "8. For production deployment, consider:"
        echo "   - Setting up SSL certificates with Let's Encrypt"
        echo "   - Configuring Nginx as reverse proxy"
        echo "   - Setting up monitoring and log rotation"
        echo "   - Configuring backup strategies"
        echo ""
        echo "Documentation: https://docs.utmstack.com"
        echo "Support: https://github.com/utmstack/UTMStack/issues"
        echo ""
        echo "=========================================="
    fi
fi