const appContainer = document.getElementById('app');

window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === "openHub") {
        appContainer.classList.remove('hidden');
    } else if (data.action === "closeHub") {
        appContainer.classList.add('hidden');
    }
});

// Close UI on ESC key
document.addEventListener('keydown', (event) => {
    if (event.key === "Escape") {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            body: JSON.stringify({})
        });
    }
});

// Handle Server Selection
document.querySelectorAll('.join-btn').forEach(button => {
    button.addEventListener('click', (e) => {
        const card = e.target.closest('.server-card');
        const bucketId = card.getAttribute('data-bucket');
        
        fetch(`https://${GetParentResourceName()}/switchServer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ bucket: parseInt(bucketId) })
        });
    });
});