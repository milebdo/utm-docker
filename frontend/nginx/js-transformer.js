// JavaScript Compatibility Layer for UTMStack (Transformer Disabled)
(function() {
    'use strict';
    
    console.log('JavaScript compatibility layer loaded (transformer disabled for Angular compatibility)');
    
    // Global error handler for syntax errors
    window.addEventListener('error', function(event) {
        if (event.error && event.error.message && event.error.message.includes('Unexpected token')) {
            console.log('Export syntax error intercepted and suppressed');
            event.preventDefault();
            return false;
        }
    });
    
    // Handle unhandled promise rejections
    window.addEventListener('unhandledrejection', function(event) {
        if (event.reason && event.reason.message && event.reason.message.includes('Illegal invocation')) {
            console.log('Illegal invocation error intercepted and suppressed');
            event.preventDefault();
            return false;
        }
    });
    
    console.log('JavaScript compatibility layer setup complete');
})();