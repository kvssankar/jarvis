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

function createCollection() {
    const name = prompt("Enter collection name:");
    if (name) {
        fetch('/collections/create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ name: name })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                fetchCollections();
            }
        });
    }
}

function fetchCollections() {
    fetch('/collections')
    .then(response => response.json())
    .then(data => {
        const collectionsDiv = document.getElementById('collections');
        let html = '<div class="create-collection" onclick="createCollection()">' +
                  '<div class="plus">+</div>' +
                  '<span>Create new collection</span>' +
                  '</div>';
        
        data.collections.forEach(collection => {
            html += `
            <div class="collection">
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
            // Display tags
            const tagsContainer = document.getElementById('modalTags');
            tagsContainer.innerHTML = data.tags
                .map(tag => `<span class="tag">${tag}</span>`)
                .join('');
            
            // Display collections
            const collectionsContainer = document.getElementById('modalCollections');
            collectionsContainer.innerHTML = data.collections
                .map(collection => `<span class="modal-collection">${collection}</span>`)
                .join('');
        });
    
    modal.style.display = 'block';
}

function closeModal() {
    const modal = document.getElementById('imageModal');
    modal.style.display = 'none';
}
