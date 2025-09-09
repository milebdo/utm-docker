// JavaScript Compatibility Wrapper for UTMStack
(function() {
    'use strict';
    
    console.log('JavaScript compatibility wrapper loaded...');
    
    // Fix API URL configuration
    function fixApiConfiguration() {
        // Override any hardcoded localhost:3000 URLs
        if (window.location.hostname === 'localhost' && window.location.port === '3000') {
            console.log('Detected localhost:3000, fixing API configuration...');
            
            // Override fetch to fix API calls
            var originalFetch = window.fetch;
            window.fetch = function(url, options) {
                if (typeof url === 'string' && url.includes('localhost:3000')) {
                    var fixedUrl = url.replace('localhost:3000', '');
                    console.log('Fixed API URL:', url, '->', fixedUrl);
                    return originalFetch.call(this, fixedUrl, options);
                }
                return originalFetch.call(this, url, options);
            };
            
            // Note: XMLHttpRequest override removed to prevent conflicts with Angular HTTP client
        }
    }
    
    // Fix Angular environment configuration
    function fixAngularEnvironment() {
        // Wait for Angular to be available
        var checkAngular = setInterval(function() {
            if (window.angular) {
                clearInterval(checkAngular);
                console.log('Angular detected, fixing environment configuration...');
                
                // Try to fix the SERVER_API_URL if it's accessible
                try {
                    if (window.SERVER_API_URL && window.SERVER_API_URL.includes('localhost:3000')) {
                        window.SERVER_API_URL = '';
                        console.log('Fixed SERVER_API_URL to use relative URLs');
                    }
                } catch (e) {
                    console.log('Could not fix SERVER_API_URL directly:', e);
                }
            }
        }, 100);
    }
    
    // Fix any existing global variables
    function fixGlobalVariables() {
        // Override any global variables that might contain wrong URLs
        if (window.SERVER_API_URL && window.SERVER_API_URL.includes('localhost:3000')) {
            window.SERVER_API_URL = '';
            console.log('Fixed global SERVER_API_URL');
        }
        
        // Override any other URL-related globals
        var urlProps = ['API_URL', 'BASE_URL', 'BACKEND_URL'];
        urlProps.forEach(function(prop) {
            if (window[prop] && window[prop].includes('localhost:3000')) {
                window[prop] = '';
                console.log('Fixed global', prop);
            }
        });
    }
    
    // Initialize fixes
    function init() {
        console.log('Initializing JavaScript compatibility fixes...');
        
        // Fix API configuration
        fixApiConfiguration();
        
        // Fix Angular environment
        fixAngularEnvironment();
        
        // Fix global variables
        fixGlobalVariables();
        
        // Monitor for new script tags that might need fixing
        var observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.tagName === 'SCRIPT' && node.src) {
                            // Fix any script URLs that might contain wrong API endpoints
                            if (node.src.includes('localhost:3000')) {
                                console.log('Detected script with wrong URL:', node.src);
                            }
                        }
                    });
                }
            });
        });
        
        observer.observe(document, {
            childList: true,
            subtree: true
        });
        
        console.log('JavaScript compatibility fixes initialized');
    }
    
    // Run initialization when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
    // Also run on window load to catch late-loaded scripts
    window.addEventListener('load', function() {
        console.log('Window loaded, running additional compatibility checks...');
        fixApiConfiguration();
        fixGlobalVariables();
    });
    
    // Global error handler for XMLHttpRequest errors
    window.addEventListener('error', function(event) {
        // Handle XMLHttpRequest InvalidAccessError
        if (event.error && event.error.name === 'InvalidAccessError' && 
            event.error.message && event.error.message.includes('responseType')) {
            console.log('XMLHttpRequest InvalidAccessError intercepted and suppressed');
            event.preventDefault();
            return false;
        }
    });
    
})();
