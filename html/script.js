let currentSettings = {
    enabled: false,
    strength: 50,
    distance: 20,
    delay: 500,
    decay: 0.5,
    type: 'hall'
};

let config = {};

// Initialize UI
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'toggle') {
        const container = document.getElementById('container');
        
        if (data.show) {
            container.classList.remove('hidden');
            currentSettings = data.settings;
            config = data.config;
            updateUI();
        } else {
            container.classList.add('hidden');
        }
    } else if (data.type === 'resetSettings') {
        currentSettings = data.settings;
        updateUI();
    }
});

// Update UI elements with current settings
function updateUI() {
    // Power toggle
    document.getElementById('powerSwitch').checked = currentSettings.enabled;
    
    // Strength slider
    document.getElementById('strengthSlider').value = currentSettings.strength;
    document.getElementById('strengthValue').textContent = currentSettings.strength + '%';
    updateEqualizer(currentSettings.strength);
    
    // Distance slider
    document.getElementById('distanceSlider').value = currentSettings.distance;
    document.getElementById('distanceValue').textContent = currentSettings.distance + 'm';
    updateDistanceIndicator(currentSettings.distance);
    
    // Echo type
    document.querySelectorAll('.echo-type').forEach(type => {
        type.classList.remove('active');
    });
    document.querySelector(`[data-type="${currentSettings.type}"]`).classList.add('active');
    
    // Advanced settings
    document.getElementById('delaySlider').value = currentSettings.delay;
    document.getElementById('delayValue').textContent = currentSettings.delay + 'ms';
    
    document.getElementById('decaySlider').value = currentSettings.decay * 100;
    document.getElementById('decayValue').textContent = currentSettings.decay.toFixed(1);
    
    // Update slider ranges based on config
    if (config.maxDistance) {
        document.getElementById('distanceSlider').max = config.maxDistance;
        document.getElementById('distanceSlider').min = config.minDistance;
    }
    
    if (config.maxStrength) {
        document.getElementById('strengthSlider').max = config.maxStrength;
        document.getElementById('strengthSlider').min = config.minStrength;
    }
}

// Event Listeners
document.getElementById('powerSwitch').addEventListener('change', function() {
    currentSettings.enabled = this.checked;
    updatePowerState();
});

document.getElementById('strengthSlider').addEventListener('input', function() {
    currentSettings.strength = parseInt(this.value);
    document.getElementById('strengthValue').textContent = this.value + '%';
    updateEqualizer(this.value);
});

document.getElementById('distanceSlider').addEventListener('input', function() {
    currentSettings.distance = parseFloat(this.value);
    document.getElementById('distanceValue').textContent = this.value + 'm';
    updateDistanceIndicator(this.value);
});

document.getElementById('delaySlider').addEventListener('input', function() {
    currentSettings.delay = parseInt(this.value);
    document.getElementById('delayValue').textContent = this.value + 'ms';
});

document.getElementById('decaySlider').addEventListener('input', function() {
    currentSettings.decay = parseInt(this.value) / 100;
    document.getElementById('decayValue').textContent = currentSettings.decay.toFixed(1);
});

// Echo type selection
document.querySelectorAll('.echo-type').forEach(type => {
    type.addEventListener('click', function() {
        document.querySelectorAll('.echo-type').forEach(t => t.classList.remove('active'));
        this.classList.add('active');
        currentSettings.type = this.dataset.type;
    });
});

// Update equalizer bars based on strength
function updateEqualizer(strength) {
    const bars = document.querySelectorAll('.bar');
    const maxHeight = 40;
    const baseHeight = 10;
    
    bars.forEach((bar, index) => {
        const randomFactor = Math.random() * 0.3 + 0.7; // 0.7 to 1.0
        const height = baseHeight + (maxHeight - baseHeight) * (strength / 100) * randomFactor;
        bar.style.height = height + 'px';
        
        // Update animation speed based on strength
        bar.style.animationDuration = (1 - strength / 200) + 0.3 + 's';
    });
}

// Update distance indicator
function updateDistanceIndicator(distance) {
    const circles = document.querySelectorAll('.range-circle');
    const maxDistance = config.maxDistance || 50;
    const intensity = distance / maxDistance;
    
    circles.forEach((circle, index) => {
        const delay = index * 0.7;
        const size = 20 + (intensity * 10);
        circle.style.width = size + 'px';
        circle.style.height = size + 'px';
        circle.style.animationDelay = delay + 's';
        circle.style.borderColor = `rgba(0, 255, 136, ${0.5 + intensity * 0.5})`;
    });
}

// Update power state visual feedback
function updatePowerState() {
    const panel = document.querySelector('.control-panel');
    const sections = document.querySelectorAll('.section:not(:first-child)');
    
    if (currentSettings.enabled) {
        panel.style.borderColor = '#00ff88';
        sections.forEach(section => {
            section.style.opacity = '1';
            section.style.pointerEvents = 'all';
        });
    } else {
        panel.style.borderColor = '#333';
        sections.forEach(section => {
            section.style.opacity = '0.5';
            section.style.pointerEvents = 'none';
        });
    }
}

// Toggle advanced settings
function toggleAdvanced() {
    const content = document.querySelector('.advanced-content');
    const button = document.querySelector('.toggle-advanced');
    
    content.classList.toggle('active');
    button.classList.toggle('active');
}

// Close UI
function closeUI() {
    const container = document.getElementById('container');
    container.classList.add('hidden');
    
        // Use the correct resource name when sending NUI callbacks.
        // The original code contained a typo ("micropone") which prevented the UI from communicating
        // with the Lua callbacks. Replace it with "micropohone" to match the resource folder name.
        fetch('https://micropohone/closeUI', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).catch(() => {
        // Fallback if fetch fails
        console.log('UI closed');
    });
}

// Preview echo
function previewEcho() {
        fetch('https://micropohone/previewEcho', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(currentSettings)
    });
    
    // Visual feedback
    const btn = document.querySelector('.btn-preview');
    const originalText = btn.innerHTML;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Playing...';
    btn.disabled = true;
    
    setTimeout(() => {
        btn.innerHTML = originalText;
        btn.disabled = false;
    }, 2000);
}

// Apply settings
function applySettings() {
        fetch('https://micropohone/updateEcho', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(currentSettings)
    });
    
    // Visual feedback
    const btn = document.querySelector('.btn-apply');
    const originalText = btn.innerHTML;
    btn.innerHTML = '<i class="fas fa-check"></i> Applied!';
    btn.style.background = 'linear-gradient(135deg, #00cc6a 0%, #009944 100%)';
    
    setTimeout(() => {
        btn.innerHTML = originalText;
        btn.style.background = 'linear-gradient(135deg, #00ff88 0%, #00cc6a 100%)';
    }, 1500);
}

// Reset settings
function resetSettings() {
        fetch('https://micropohone/resetSettings', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

// Handle ESC key to close UI
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const container = document.getElementById('container');
        container.classList.add('hidden');
        closeUI();
    }
});

// Initialize animations on load
window.addEventListener('load', function() {
    updateEqualizer(50);
    updateDistanceIndicator(20);
    updatePowerState();
});

// Add smooth scrolling for better UX
document.querySelector('.control-panel').addEventListener('wheel', function(e) {
    e.preventDefault();
    this.scrollTop += e.deltaY * 0.5;
});