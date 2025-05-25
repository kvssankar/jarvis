function toggleCollections() {
    const collections = document.getElementById('collections');
    collections.style.display = collections.style.display === 'none' ? 'block' : 'none';
}

function processImages() {
    fetch('/process', {
        method: 'POST',
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            fetchCollections();
            location.reload();
        }
    });
}

function scanDirectory() {
    const path = document.getElementById('directoryPath').value;
    fetch('/scan', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ path: path })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            location.reload();
        }
    });
}

function openCollectionModal() {
    const modal = document.getElementById('collectionModal');
    modal.style.display = 'block';
    
    // Clear previous values
    document.getElementById('collectionName').value = '';
    document.getElementById('collectionDescription').value = '';
}

function closeCollectionModal() {
    const modal = document.getElementById('collectionModal');
    modal.style.display = 'none';
}

function submitCollection() {
    const name = document.getElementById('collectionName').value.trim();
    const description = document.getElementById('collectionDescription').value.trim();
    
    if (!name) {
        alert('Please enter a collection name');
        return;
    }
    
    fetch('/collections/create', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ name: name, description: description })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            closeCollectionModal();
            fetchCollections();
        } else {
            alert(data.error || 'Failed to create collection');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Failed to create collection');
    });
}

function fetchCollections() {
    const collectionsDiv = document.getElementById('collections');
    // Only fetch collections if we're on a page with the collections div
    if (collectionsDiv) {
        fetch('/collections')
        .then(response => response.json())
        .then(data => {
            let html = '<div class="create-collection" onclick="openCollectionModal()">' +
                      '<div class="plus">+</div>' +
                      '<span>Create new collection</span>' +
                      '</div>';
            
            data.collections.forEach(collection => {
                html += `
                <div class="collection" onclick="window.location.href='/collections/${encodeURIComponent(collection.name)}'">
                    <div class="collection-preview">
                        ${collection.preview ? `<img src="${collection.preview}" alt="${collection.name}">` : ''}
                    </div>
                    <div class="collection-info">
                        <h3>${collection.name}</h3>
                        <p>${collection.count} images</p>
                    </div>
                </div>`;
            });
            collectionsDiv.innerHTML = html;
        });
    }
}

// Load collections on page load
document.addEventListener('DOMContentLoaded', () => {
    fetchCollections();
    setupModal();
});

// Modal functionality
function setupModal() {
    const modal = document.getElementById('imageModal');
    const closeBtn = document.querySelector('.close');
    
    // Add click listeners to all image tiles
    const imageTiles = document.querySelectorAll('.image-tile');
    imageTiles.forEach(tile => {
        tile.addEventListener('click', function() {
            const img = this.querySelector('img');
            openImageModal(img.src, img.getAttribute('src'));
        });
    });
    
    // Close modal when clicking the X
    closeBtn.addEventListener('click', closeModal);
    
    // Close modal when clicking outside
    window.addEventListener('click', (event) => {
        if (event.target === modal) {
            closeModal();
        }
    });
}

function openImageModal(displaySrc, filePath) {
    const modal = document.getElementById('imageModal');
    const modalImg = document.getElementById('modalImage');
    
    modalImg.src = displaySrc;
    
    // Fetch and display image details
    fetch(`/image${filePath}/details`)
        .then(response => response.json())
        .then(data => {
            const tagsContainer = document.getElementById('modalTags');
            tagsContainer.innerHTML = data.tags
                .map(tag => `<span class="tag">${tag}</span>`)
                .join('');
            
            // Fetch all collections and create checkboxes
            fetch('/collections')
                .then(response => response.json())
                .then(collectionsData => {
                    const checkboxesContainer = document.querySelector('.collection-checkboxes');
                    checkboxesContainer.innerHTML = collectionsData.collections
                        .map(collection => `
                            <div class="collection-checkbox">
                                <input type="checkbox" 
                                       id="collection-${collection.name}" 
                                       value="${collection.name}"
                                       ${data.collections.includes(collection.name) ? 'checked' : ''}>
                                <label for="collection-${collection.name}">${collection.name}</label>
                            </div>
                        `).join('');
                    
                    // Add save button event listener
                    document.getElementById('saveCollections').onclick = () => {
                        const selectedCollections = Array.from(checkboxesContainer.querySelectorAll('input[type="checkbox"]:checked'))
                            .map(checkbox => checkbox.value);
                            
                        fetch(`/image${filePath}/update_collections`, {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json'
                            },
                            body: JSON.stringify({ collections: selectedCollections })
                        })
                        .then(response => response.json())
                        .then(result => {
                            if (result.success) {
                                // Refresh collections display
                                fetchCollections();
                                closeModal();
                            }
                        });
                    };
                });
        });
    
    modal.style.display = 'block';
}

function closeModal() {
    const modal = document.getElementById('imageModal');
    modal.style.display = 'none';
}
