// Configuration
const API_CONFIG = {
    baseUrl: 'http://localhost:5000/api',
    endpoints: {
        searchProducts: '/searchProducts'
    }
};

// DOM Elements
let searchInput, categoryInput, searchBtn, loadingState, errorState, 
    resultsSection, emptyState, resultsContainer, resultCount, errorMessage;

// Initialize when DOM is ready
$(document).ready(function() {
    initializeElements();
    setupEventListeners();
    showEmptyState();
});

/**
 * Initialize DOM elements
 */
function initializeElements() {
    searchInput = $('#searchInput');
    categoryInput = $('#categoryInput');
    searchBtn = $('#searchBtn');
    loadingState = $('#loadingState');
    errorState = $('#errorState');
    resultsSection = $('#resultsSection');
    emptyState = $('#emptyState');
    resultsContainer = $('#resultsContainer');
    resultCount = $('#resultCount');
    errorMessage = $('#errorMessage');
}

/**
 * Setup event listeners
 */
function setupEventListeners() {
    // Form submission
    $('#searchForm').on('submit', function(e) {
        e.preventDefault();
        performSearch();
    });

    // Enter key handling for Fluent UI text fields
    searchInput.on('keypress', function(e) {
        if (e.which === 13) {
            e.preventDefault();
            performSearch();
        }
    });

    categoryInput.on('keypress', function(e) {
        if (e.which === 13) {
            e.preventDefault();
            performSearch();
        }
    });

    // Remove real-time search - only search on Enter or button click
    // This section intentionally removed to prevent automatic searching
}

/**
 * Perform product search
 */
async function performSearch() {
    const searchTerm = searchInput.val().trim();
    const category = categoryInput.val().trim();

    if (!searchTerm) {
        showError('Please enter a search term');
        return;
    }

    try {
        showLoading();
        
        const results = await searchProducts(searchTerm, category);
        
        if (results && results.value && results.value.length > 0) {
            showResults(results.value);
        } else {
            showNoResults();
        }
        
    } catch (error) {
        console.error('Search failed:', error);
        showError('Failed to search products. Please check if the API is running on localhost:5000');
    }
}

/**
 * Call the Data API Builder endpoint
 */
async function searchProducts(searchTerm, category = '') {
    const response = await fetch(`${API_CONFIG.baseUrl}${API_CONFIG.endpoints.searchProducts}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            searchTerm: searchTerm,
            category: category
        })
    });

    if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json();
}

/**
 * Display search results
 */
function showResults(products) {
    hideAllStates();
    
    resultCount.text(`${products.length} product${products.length !== 1 ? 's' : ''} found`);
    
    resultsContainer.empty();
    
    products.forEach((product, index) => {
        const productCard = createProductCard(product, index);
        resultsContainer.append(productCard);
    });
    
    resultsSection.addClass('fade-in').show();
    searchBtn.prop('disabled', false).html('<i class="ms-Icon ms-Icon--Search mr-2"></i>Search Products');
}

/**
 * Create a product card HTML element
 */
function createProductCard(product, index) {
    const categories = product.category ? product.category.split('|').filter(c => c.trim()) : [];
    const categoryBadges = categories.map(cat => 
        `<span class="category-badge px-2 py-1 text-xs rounded-full">${escapeHtml(cat)}</span>`
    ).join(' ');

    const thoughtsSection = product.thoughts ? 
        `<div class="mt-3 p-3 bg-blue-50 rounded-lg border-l-4 border-blue-400">
            <div class="flex items-start">
                <i class="ms-Icon ms-Icon--Lightbulb text-blue-500 mt-1 mr-2"></i>
                <div>
                    <h4 class="text-sm font-medium text-blue-800 mb-1">AI Insights</h4>
                    <p class="text-sm text-blue-700">${escapeHtml(product.thoughts)}</p>
                </div>
            </div>
        </div>` : '';

    return `
        <div class="product-card bg-white rounded-xl shadow-md p-6 fade-in" style="animation-delay: ${index * 0.1}s">
            <div class="flex items-start justify-between mb-4">
                <div class="flex-1">
                    <h3 class="text-lg font-semibold text-gray-800 mb-2 leading-tight">
                        ${escapeHtml(product.product_name)}
                    </h3>
                    <div class="flex flex-wrap gap-1 mb-3">
                        ${categoryBadges}
                    </div>
                </div>
                <div class="ml-4 text-right">
                    <span class="text-sm font-medium text-gray-500">ID: ${product.id}</span>
                </div>
            </div>
            
            <div class="mb-4">
                <p class="text-gray-600 text-sm leading-relaxed">
                    ${escapeHtml(product.short_description || 'No short description available')}
                </p>
            </div>
            
            ${product.description ? `
                <div class="mb-4">
                    <details class="group">
                        <summary class="cursor-pointer text-sm font-medium text-gray-700 hover:text-blue-600 transition-colors flex items-center">
                            <i class="ms-Icon ms-Icon--Info mr-2"></i>
                            Full Description
                            <i class="ms-Icon ms-Icon--ChevronDown ml-2 group-open:rotate-180 transition-transform"></i>
                        </summary>
                        <div class="pt-2 mt-2">
                            <p class="text-gray-600 text-sm leading-relaxed">
                                ${escapeHtml(formatDescription(product.description))}
                            </p>
                        </div>
                    </details>
                </div>
            ` : ''}
            
            ${thoughtsSection}
        </div>
    `;
}

/**
 * Format product description
 */
function formatDescription(description) {
    if (!description) return '';
    
    // Remove pipe characters and clean up formatting
    return description
        .replace(/\|/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Show loading state
 */
function showLoading() {
    hideAllStates();
    loadingState.show();
    searchBtn.prop('disabled', true).text('Searching...');
}

/**
 * Show error state
 */
function showError(message) {
    hideAllStates();
    errorMessage.text(message);
    errorState.show();
    searchBtn.prop('disabled', false).html('<i class="ms-Icon ms-Icon--Search mr-2"></i>Search Products');
}

/**
 * Show empty state
 */
function showEmptyState() {
    hideAllStates();
    emptyState.show();
    searchBtn.prop('disabled', false).html('<i class="ms-Icon ms-Icon--Search mr-2"></i>Search Products');
}

/**
 * Show no results message
 */
function showNoResults() {
    hideAllStates();
    
    const noResultsHtml = `
        <div class="text-center py-16">
            <div class="max-w-md mx-auto">
                <i class="ms-Icon ms-Icon--SearchIssue text-6xl text-gray-300 mb-4"></i>
                <h3 class="text-xl font-semibold text-gray-600 mb-2">No Products Found</h3>
                <p class="text-gray-500 mb-4">We couldn't find any products matching your search criteria.</p>
                <button class="btn-primary px-4 py-2 rounded-lg" onclick="clearSearch()">
                    <i class="ms-Icon ms-Icon--Refresh mr-2"></i>
                    Try Different Keywords
                </button>
            </div>
        </div>
    `;
    
    resultsSection.html(noResultsHtml).show();
    searchBtn.prop('disabled', false).html('<i class="ms-Icon ms-Icon--Search mr-2"></i>Search Products');
}

/**
 * Hide all state elements
 */
function hideAllStates() {
    loadingState.hide();
    errorState.hide();
    resultsSection.hide();
    emptyState.hide();
}

/**
 * Clear error state
 */
function clearError() {
    showEmptyState();
}

/**
 * Clear search and return to empty state
 */
function clearSearch() {
    searchInput.val('');
    categoryInput.val('');
    showEmptyState();
    searchInput.focus();
}

/**
 * Set example query
 */
function setExampleQuery(query) {
    searchInput.val(query);
    searchInput.focus();
    // Small delay to ensure the value is set before triggering search
    setTimeout(() => {
        performSearch();
    }, 100);
}

/**
 * Utility function to check API connectivity
 */
async function checkApiConnectivity() {
    try {
        const response = await fetch(`${API_CONFIG.baseUrl}/health`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            }
        });
        return response.ok;
    } catch (error) {
        return false;
    }
}

// Export functions for global access
window.clearError = clearError;
window.clearSearch = clearSearch;
window.setExampleQuery = setExampleQuery;