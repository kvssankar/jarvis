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
document.addEventListener('DOMContentLoaded', fetchCollections);
