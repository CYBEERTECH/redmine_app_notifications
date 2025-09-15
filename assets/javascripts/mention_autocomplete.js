// @ Mention Autocomplete for Redmine
document.addEventListener('DOMContentLoaded', function() {
  // Find all text areas that could contain mentions
  const textAreas = document.querySelectorAll('textarea[name*="notes"], textarea[name*="description"], textarea#issue_description, textarea#journal_notes');
  
  textAreas.forEach(function(textarea) {
    setupMentionAutocomplete(textarea);
  });
  
  function setupMentionAutocomplete(textarea) {
    let mentionDropdown = null;
    let currentMentionStart = -1;
    let users = [];
    
    // Fetch users for autocomplete
    function fetchUsers() {
      fetch('/users.json')
        .then(response => response.json())
        .then(data => {
          users = data.users || [];
        })
        .catch(err => console.log('Failed to fetch users:', err));
    }
    
    // Create dropdown element
    function createDropdown() {
      const dropdown = document.createElement('div');
      dropdown.className = 'mention-autocomplete-dropdown';
      dropdown.style.cssText = `
        position: absolute;
        background: white;
        border: 1px solid #ccc;
        border-radius: 4px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        max-height: 200px;
        overflow-y: auto;
        z-index: 1000;
        display: none;
      `;
      document.body.appendChild(dropdown);
      return dropdown;
    }
    
    // Position dropdown near cursor
    function positionDropdown(textarea, dropdown) {
      const rect = textarea.getBoundingClientRect();
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
      const scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
      
      dropdown.style.left = (rect.left + scrollLeft) + 'px';
      dropdown.style.top = (rect.bottom + scrollTop) + 'px';
      dropdown.style.minWidth = '200px';
    }
    
    // Show dropdown with filtered users
    function showDropdown(query) {
      if (!mentionDropdown) {
        mentionDropdown = createDropdown();
      }
      
      const filteredUsers = users.filter(user => 
        user.login.toLowerCase().includes(query.toLowerCase()) ||
        (user.firstname && user.firstname.toLowerCase().includes(query.toLowerCase())) ||
        (user.lastname && user.lastname.toLowerCase().includes(query.toLowerCase()))
      ).slice(0, 10);
      
      if (filteredUsers.length === 0) {
        hideDropdown();
        return;
      }
      
      mentionDropdown.innerHTML = '';
      filteredUsers.forEach((user, index) => {
        const item = document.createElement('div');
        item.className = 'mention-item';
        item.style.cssText = `
          padding: 8px 12px;
          cursor: pointer;
          border-bottom: 1px solid #eee;
        `;
        item.innerHTML = `
          <strong>${user.login}</strong>
          ${user.firstname && user.lastname ? `<br><small>${user.firstname} ${user.lastname}</small>` : ''}
        `;
        
        item.addEventListener('mouseenter', () => {
          document.querySelectorAll('.mention-item').forEach(i => i.style.background = '');
          item.style.background = '#f0f0f0';
        });
        
        item.addEventListener('click', () => {
          insertMention(user.login);
        });
        
        mentionDropdown.appendChild(item);
      });
      
      positionDropdown(textarea, mentionDropdown);
      mentionDropdown.style.display = 'block';
    }
    
    // Hide dropdown
    function hideDropdown() {
      if (mentionDropdown) {
        mentionDropdown.style.display = 'none';
      }
    }
    
    // Insert mention into textarea
    function insertMention(login) {
      const text = textarea.value;
      const beforeMention = text.substring(0, currentMentionStart);
      const afterCursor = text.substring(textarea.selectionStart);
      
      textarea.value = beforeMention + '@' + login + ' ' + afterCursor;
      
      const newCursorPos = beforeMention.length + login.length + 2;
      textarea.setSelectionRange(newCursorPos, newCursorPos);
      textarea.focus();
      
      hideDropdown();
      currentMentionStart = -1;
    }
    
    // Handle keyboard input
    textarea.addEventListener('input', function(e) {
      const cursorPos = textarea.selectionStart;
      const text = textarea.value;
      
      // Find @ symbol before cursor
      let atPos = -1;
      for (let i = cursorPos - 1; i >= 0; i--) {
        if (text[i] === '@') {
          atPos = i;
          break;
        }
        if (text[i] === ' ' || text[i] === '\n') {
          break;
        }
      }
      
      if (atPos >= 0) {
        const query = text.substring(atPos + 1, cursorPos);
        if (query.length >= 0 && !query.includes(' ')) {
          currentMentionStart = atPos;
          showDropdown(query);
          return;
        }
      }
      
      hideDropdown();
      currentMentionStart = -1;
    });
    
    // Handle keyboard navigation
    textarea.addEventListener('keydown', function(e) {
      if (!mentionDropdown || mentionDropdown.style.display === 'none') {
        return;
      }
      
      const items = mentionDropdown.querySelectorAll('.mention-item');
      let selectedIndex = -1;
      
      items.forEach((item, index) => {
        if (item.style.background === 'rgb(240, 240, 240)') {
          selectedIndex = index;
        }
      });
      
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        selectedIndex = Math.min(selectedIndex + 1, items.length - 1);
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        selectedIndex = Math.max(selectedIndex - 1, 0);
      } else if (e.key === 'Enter' && selectedIndex >= 0) {
        e.preventDefault();
        items[selectedIndex].click();
        return;
      } else if (e.key === 'Escape') {
        hideDropdown();
        return;
      }
      
      // Update selection
      items.forEach((item, index) => {
        item.style.background = index === selectedIndex ? '#f0f0f0' : '';
      });
    });
    
    // Hide dropdown when clicking outside
    document.addEventListener('click', function(e) {
      if (!mentionDropdown || !mentionDropdown.contains(e.target)) {
        hideDropdown();
      }
    });
    
    // Initialize users
    fetchUsers();
  }
});
