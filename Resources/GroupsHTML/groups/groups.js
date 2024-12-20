// Set current year dynamically
document.getElementById('currentYear').textContent = new Date().getFullYear();

// We'll load permissions.txt and parse it
function loadPermissionDescriptions(url) {
    return fetch(url)
        .then(response => response.text())
        .then(text => {
            const lines = text.split('\n');
            const descMap = {};
            for (const line of lines) {
                const trimmed = line.trim();
                if (!trimmed || trimmed.startsWith('#')) continue; // Skip empty or commented lines
                const parts = trimmed.split('=');
                if (parts.length === 2) {
                    const key = parts[0].trim();
                    const value = parts[1].trim();
                    descMap[key] = value;
                }
            }
            return descMap;
        });
}

Promise.all([
    fetch('./groups.json').then(r => r.json()),
    loadPermissionDescriptions('./permissions.txt') // Adjust path as needed
]).then(([data, permissionDescriptions]) => {
    const groupsArray = Object.keys(data).map(groupName => {
        const perms = data[groupName].permissions || [];

        let groupWeight = 0; 
        let displayName = null;

        for (const p of perms) {
            if (p.permission.startsWith("weight.")) {
                const parts = p.permission.split(".");
                if (parts.length === 2) {
                    const w = parseInt(parts[1], 10);
                    if (!isNaN(w)) {
                        groupWeight = w;
                    }
                }
            }
            if (p.permission.startsWith("displayname.")) {
                const dnParts = p.permission.split(".");
                if (dnParts.length === 2) {
                    displayName = dnParts[1];
                }
            }
        }

        return {
            name: groupName,
            permissions: perms,
            weight: groupWeight,
            displayName: displayName
        };
    });

    // Sort groups by weight in ascending order
    groupsArray.sort((a, b) => a.weight - b.weight);

    const container = document.getElementById('content');
    const groupList = document.getElementById('group-list');

    groupsArray.forEach(group => {
        const groupId = 'group-' + group.name; // unique anchor ID

        // Create the index link at the top
        const liIndex = document.createElement('li');
        if (group.displayName) {
            const linkIndex = document.createElement('a');
            linkIndex.href = `#${groupId}`;
            linkIndex.textContent = group.displayName;
            liIndex.appendChild(linkIndex);

            const groupNameText = document.createTextNode(` (${group.name})`);
            liIndex.appendChild(groupNameText);
        } else {
            const linkIndex = document.createElement('a');
            linkIndex.href = `#${groupId}`;
            linkIndex.textContent = group.name;
            liIndex.appendChild(linkIndex);
        }
        groupList.appendChild(liIndex);

        const groupDiv = document.createElement('div');
        groupDiv.className = 'group';
        groupDiv.id = groupId;

        const h2 = document.createElement('h2');

        const arrowLink = document.createElement('a');
        arrowLink.href = '#top';
        arrowLink.className = 'top-link';
        arrowLink.textContent = '↑';
        h2.appendChild(arrowLink);

        const titleSpan = document.createElement('span');
        titleSpan.style.marginLeft = '10px';

        if (group.displayName) {
            titleSpan.appendChild(document.createTextNode('Group: '));
            const strongDisplayName = document.createElement('strong');
            strongDisplayName.textContent = group.displayName;
            titleSpan.appendChild(strongDisplayName);
            titleSpan.appendChild(document.createTextNode(` (${group.name})`));
        } else {
            titleSpan.textContent = `Group: ${group.name}`;
        }

        h2.appendChild(titleSpan);
        groupDiv.appendChild(h2);

        const ul = document.createElement('ul');
        ul.className = "permissions";

        if (group.permissions.length > 0) {
            group.permissions.forEach(p => {
                const li = document.createElement('li');

                // Description
                const desc = permissionDescriptions[p.permission] || '???';
                const descriptionDiv = document.createElement('div');
                descriptionDiv.className = 'perm-description';
                // Description: normal label, bold desc
                descriptionDiv.innerHTML = `Description: <span class="desc-bold">${desc}</span>`;
                li.appendChild(descriptionDiv);

                // Value Display
                const valueDiv = document.createElement('div');
                valueDiv.className = 'perm-detail';
                let valueContent;
                if (p.value === true) {
                    valueContent = '<span class="value-true">true</span>';
                } else if (p.value === false) {
                    valueContent = '<span class="value-false">false</span>';
                } else {
                    valueContent = `<span class="value-other">${p.value}</span>`;
                }
                valueDiv.innerHTML = "Value: " + valueContent;
                li.appendChild(valueDiv);

                // Context Display
                const contextDiv = document.createElement('div');
                contextDiv.className = 'perm-context';
                if (p.context && Object.keys(p.context).length > 0) {
                    contextDiv.classList.add('context-block');
                    let contextText = "Context:";
                    for (const key of Object.keys(p.context)) {
                        const val = p.context[key];
                        if (Array.isArray(val)) {
                            contextText += `\n- ${key}: ${val.join(', ')}`;
                        } else {
                            contextText += `\n- ${key}: ${val}`;
                        }
                    }
                    contextDiv.textContent = contextText;
                } else {
                    // None context
                    contextDiv.innerHTML = `Context: <span class="context-none">None</span>`;
                }
                li.appendChild(contextDiv);

                // Permission line
                const permDiv = document.createElement('div');
                permDiv.className = 'permission-line';
                permDiv.innerHTML = `Permission: <span class="perm-bold">${p.permission}</span>`;
                li.appendChild(permDiv);

                ul.appendChild(li);
            });
        } else {
            const noPerm = document.createElement('li');
            noPerm.textContent = "No permissions found.";
            noPerm.className = 'no-matches';
            ul.appendChild(noPerm);
        }

        groupDiv.appendChild(ul);
        container.appendChild(groupDiv);
    });

    // Search functionality
    const searchInput = document.getElementById('search-input');
    searchInput.addEventListener('input', () => {
        const filter = searchInput.value.toLowerCase();
        const groups = document.querySelectorAll('.group');

        groups.forEach(groupEl => {
            const permissions = groupEl.querySelectorAll('ul.permissions li');
            permissions.forEach(li => {
                if (li.classList.contains('no-matches')) return;

                const liText = li.innerText.toLowerCase();
                if (liText.includes(filter)) {
                    li.classList.remove('permission-hidden');
                } else {
                    li.classList.add('permission-hidden');
                }
            });
        });
    });
}).catch(error => {
    const container = document.getElementById('content');
    container.textContent = "Error loading groups data or permissions file: " + error;
});
