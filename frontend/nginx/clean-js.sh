#!/bin/bash

# Clean JavaScript files by removing ES6 export statements
echo "Cleaning JavaScript files..."

# Function to clean a JavaScript file
clean_js_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    echo "Cleaning $file..."
    
    # Remove export statements that cause syntax errors
    sed -E 's/export\s+\{[^}]*\};?/\/\/ export statements removed for compatibility/g' "$file" > "$temp_file"
    sed -i -E 's/export\s+default\s+[^;]*;?/\/\/ export default removed for compatibility/g' "$temp_file"
    sed -i -E 's/export\s+[a-zA-Z_$][a-zA-Z0-9_$]*\s+from\s+["'"'"'][^"'"'"']*["'"'"'];?/\/\/ export from removed for compatibility/g' "$temp_file"
    
    # Remove import statements
    sed -i -E 's/import\s+[^;]*from\s+["'"'"'][^"'"'"']*["'"'"'];?/\/\/ import statements removed for compatibility/g' "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$file"
    echo "Cleaned $file"
}

# Clean the problematic JavaScript files
cd /usr/share/nginx/html

# Clean scripts file
if [ -f "scripts.8ab6740a0988d6579867.js" ]; then
    clean_js_file "scripts.8ab6740a0988d6579867.js"
fi

# Clean main file
if [ -f "main.3b907159dda75f07e685.js" ]; then
    clean_js_file "main.3b907159dda75f07e685.js"
fi

echo "JavaScript files cleaned successfully!"
