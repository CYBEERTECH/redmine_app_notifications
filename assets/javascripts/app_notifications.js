// /opt/redmine/plugins/redmine_app_notifications/assets/javascripts/app_notifications.js

// Handles notifications + timestamps
document.addEventListener('DOMContentLoaded', function () {
  const list = document.getElementById('app-notifications-list');
  if (!list) return;

  // === TIMESTAMP UPDATER & REPOSITIONER ===
  function updateTimes() {
    // 1) update the “x minutes/hours ago” text
    document.querySelectorAll('.notification-time').forEach(el => {
      const ts = el.getAttribute('data-timestamp');
      if (!ts) return;
      const created = new Date(ts);
      const now = new Date();
      const diffMs   = now - created;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHrs  = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHrs / 24);
      let text;
      if (diffMins < 60) {
        text = `${diffMins} minute${diffMins !== 1 ? 's' : ''} ago`;
      } else if (diffHrs < 24) {
        text = `${diffHrs} hour${diffHrs !== 1 ? 's' : ''} ago`;
      } else {
        text = `${diffDays} day${diffDays !== 1 ? 's' : ''} ago`;
      }
      el.textContent = text;
    });

    // 2) for each notification, if there’s an “Assignee:” line, move the timestamp right beneath it
    document.querySelectorAll('.app-notification').forEach(container => {
      const timeEl = container.querySelector('.notification-time');
      if (!timeEl) return;

      // find the node whose text starts with “Assignee:”
      const detailNodes = Array.from(container.querySelectorAll('div, p, li, span'));
      const assigneeLine = detailNodes.find(n => n.textContent.trim().startsWith('Assignee:'));
      if (assigneeLine) {
        // ensure it’s its own line
        timeEl.style.display = 'block';
        // only move it if not already there
        if (assigneeLine.nextSibling !== timeEl) {
          assigneeLine.insertAdjacentElement('afterend', timeEl);
        }
      }
    });
  }

  updateTimes();
  setInterval(updateTimes, 60000);

  // === ACTION HANDLERS ===
  list.addEventListener('click', function (e) {
    const link = e.target.closest('a');
    if (!link) return;
    const action = link.textContent.trim();
    const actionKey = action.toLowerCase();
    const container = link.closest('.app-notification');
    if (!container) return;

if (actionKey === 'mark as read' || actionKey === 'mark as unread') {
  const markRead = action === 'Mark as read';
  // remove or add the unread highlight
  container.classList.toggle('unread', !markRead);

  // swap link text and icon
  if (markRead) {
    link.textContent = 'Mark as unread';
    link.classList.replace('icon-unchecked','icon-checked');
  } else {
    link.textContent = 'Mark as read';
    link.classList.replace('icon-checked','icon-unchecked');
  }

  // flip the AJAX endpoint
  link.href = link.href.replace(
    markRead ? 'mark_as_read' : 'mark_as_unread',
    markRead ? 'mark_as_unread' : 'mark_as_read'
  );

  e.preventDefault();
  fetch(link.href, { method: 'PATCH', headers: { 'X-CSRF-Token': getCSRF() } });
  return;
}



    if (action === 'Delete') {
      e.preventDefault();
      fetch(link.href, { method: 'DELETE', headers: { 'X-CSRF-Token': getCSRF() } })
        .then(() => container.remove());
      return;
    }
  });

  const deleteAllBtn = document.querySelector('a.icon-del[href*="delete_all"]');
  if (deleteAllBtn) {
    deleteAllBtn.addEventListener('click', function (e) {
      e.preventDefault();
      fetch(deleteAllBtn.href, { method: 'DELETE', headers: { 'X-CSRF-Token': getCSRF() } })
        .then(() => list.innerHTML = '');
    });
  }

const markAllBtn = document.querySelector('a[href*="mark_all"]');
if (markAllBtn) {
  markAllBtn.addEventListener('click', function (e) {
    e.preventDefault();
    const isMarkAllRead = markAllBtn.textContent.trim() === 'Mark all as read';
    fetch(markAllBtn.href, { method: 'PATCH', headers: { 'X-CSRF-Token': getCSRF() } })
      .then(() => {
        document.querySelectorAll('.app-notification').forEach(n => {
          if (isMarkAllRead) {
            n.classList.remove('unread');
          } else {
            n.classList.add('unread');
          }
        });
        markAllBtn.textContent = isMarkAllRead
          ? 'Mark all as unread'
          : 'Mark all as read';
      });
  });
}

  function getCSRF() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : '';
  }
});

// 🔔 Bell icon functionality for header with sound notifications
document.addEventListener('DOMContentLoaded', function(){
  let lastNotificationCount = 0;
  let soundEnabled = true;
  
  // Check if sound is enabled in user settings
  const soundSetting = localStorage.getItem('app_notifications_sound');
  if (soundSetting !== null) {
    soundEnabled = soundSetting === 'true';
  }
  
  updateNotificationBell();
  
  // Update bell every 30 seconds
  setInterval(updateNotificationBell, 30000);
  
  function playNotificationSound() {
    if (!soundEnabled) return;
    
    try {
      var audio = new Audio('/plugin_assets/redmine_app_notifications/sounds/notification.mp3');
      audio.volume = 0.5;
      audio.play().catch(function(error) {
        console.log('Could not play notification sound:', error);
        // Fallback to beep using Web Audio API
        try {
          var audioContext = new (window.AudioContext || window.webkitAudioContext)();
          var oscillator = audioContext.createOscillator();
          var gainNode = audioContext.createGain();
          
          oscillator.connect(gainNode);
          gainNode.connect(audioContext.destination);
          
          oscillator.frequency.value = 800;
          oscillator.type = 'sine';
          
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
          
          oscillator.start(audioContext.currentTime);
          oscillator.stop(audioContext.currentTime + 0.5);
        } catch (beepError) {
          console.log('Could not play fallback beep:', beepError);
        }
      });
    } catch (error) {
      console.log('Audio not supported:', error);
    }
  }

  function testNotificationSound() {
    console.log('Testing notification sound...');
    playNotificationSound();
  }

  function updateNotificationBell() {
    const bellIcon = document.querySelector('#notifications-bell');
    if (!bellIcon) return;
    
    fetch('/app_notifications/count.json')
      .then(r => r.json())
      .then(data => {
        const countSpan = bellIcon.querySelector('.notification-count');
        const currentCount = data.count || 0;
        
        // Play sound if count increased
        if (currentCount > lastNotificationCount && lastNotificationCount > 0) {
          playNotificationSound();
        }
        lastNotificationCount = currentCount;
        
        if (currentCount > 0) {
          bellIcon.classList.add('active');
          bellIcon.title = `${currentCount} unread notifications`;
          
          if (countSpan) {
            countSpan.textContent = currentCount;
          } else {
            const newCountSpan = document.createElement('span');
            newCountSpan.className = 'notification-count';
            newCountSpan.textContent = currentCount;
            bellIcon.appendChild(newCountSpan);
          }
        } else {
          bellIcon.classList.remove('active');
          bellIcon.title = 'No unread notifications';
          if (countSpan) {
            countSpan.remove();
          }
        }
      })
      .catch(err => console.log('Notification count fetch failed:', err));
  }
  
  // Add sound toggle functionality
  function addSoundToggle() {
    const bellIcon = document.querySelector('#notifications-bell');
    if (!bellIcon) return;
    
    // Add right-click context menu for sound toggle
    bellIcon.addEventListener('contextmenu', function(e) {
      e.preventDefault();
      
      const menu = document.createElement('div');
      menu.style.cssText = `
        position: fixed;
        background: white;
        border: 1px solid #ccc;
        border-radius: 4px;
        padding: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        z-index: 1001;
        left: ${e.clientX}px;
        top: ${e.clientY}px;
      `;
      
      const toggleItem = document.createElement('div');
      toggleItem.style.cssText = 'cursor: pointer; padding: 4px 8px;';
      toggleItem.textContent = soundEnabled ? '🔇 Disable Sound' : '🔊 Enable Sound';
      
      toggleItem.addEventListener('click', function() {
        soundEnabled = !soundEnabled;
        localStorage.setItem('app_notifications_sound', soundEnabled.toString());
        document.body.removeChild(menu);
      });
      
      menu.appendChild(toggleItem);
      document.body.appendChild(menu);
      
      // Remove menu when clicking elsewhere
      setTimeout(() => {
        document.addEventListener('click', function removeMenu() {
          if (document.body.contains(menu)) {
            document.body.removeChild(menu);
          }
          document.removeEventListener('click', removeMenu);
        });
      }, 100);
    });
  }
  
  // Initialize sound toggle after a short delay
  setTimeout(addSoundToggle, 1000);
});

