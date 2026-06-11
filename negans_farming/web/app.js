const app = document.getElementById('app');
const closeButton = document.getElementById('close');
const tabs = Array.from(document.querySelectorAll('.tab'));
const pages = Array.from(document.querySelectorAll('.tab-page'));

let latestData = null;
app.style.display = 'none';

function post(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
}

function percent(value, min, max) {
    if (!max || max <= min) return 100;
    return Math.max(0, Math.min(100, ((value - min) / (max - min)) * 100));
}

function money(value) {
    return `$${Number(value || 0).toLocaleString()}`;
}

function setText(id, value) {
    document.getElementById(id).textContent = value;
}

function card(html, locked = false) {
    const element = document.createElement('article');
    element.className = `card${locked ? ' locked' : ''}`;
    element.innerHTML = html;
    return element;
}

function renderSummary(data) {
    const player = data.player || {};
    const currentLevelXP = player.currentLevelXP || 0;
    const nextLevelXP = player.nextLevelXP || player.xp || 0;
    const tier = player.tier || {};
    const nextTier = player.nextTier;

    setText('level', `Level ${player.level || 1}`);
    setText('xpText', nextLevelXP > player.xp
        ? `${player.xp || 0} / ${nextLevelXP} XP`
        : `${player.xp || 0} XP, max level`);
    document.getElementById('xpBar').style.width = `${percent(player.xp || 0, currentLevelXP, nextLevelXP)}%`;

    setText('tier', tier.label || 'Roadside Seller');
    setText('repText', nextTier
        ? `${player.reputation || 0} / ${nextTier.required} reputation`
        : `${player.reputation || 0} reputation, top tier`);
    document.getElementById('repBar').style.width = `${nextTier ? percent(player.reputation || 0, tier.required || 0, nextTier.required) : 100}%`;
}

function renderOrders(data) {
    const list = document.getElementById('ordersList');
    list.innerHTML = '';
    const orders = data.orders || [];

    document.getElementById('orderReset').textContent = orders[0] ? `Resets ${orders[0].reset}` : '';

    if (!orders.length) {
        list.appendChild(card('<h3>No buyer orders</h3><p>Daily orders are disabled in config.</p>'));
        return;
    }

    orders.forEach((order) => {
        const bonus = Math.floor((order.bonusMultiplier - 1) * 100);
        const progress = `${order.sold}/${order.amount}`;
        list.appendChild(card(`
            <h3>${order.label}</h3>
            <p>${order.complete ? 'Order complete for today.' : `${order.remaining} bottles still qualify for the bonus.`}</p>
            <div class="pill-row">
                <span class="pill gold">+${bonus}%</span>
                <span class="pill">${money(order.basePrice)} base</span>
                ${order.rare ? '<span class="pill red">Rare</span>' : ''}
            </div>
            <div class="progress-text">Progress: ${progress}</div>
        `, order.complete));
    });
}

function renderRecipes(data) {
    const list = document.getElementById('recipesList');
    list.innerHTML = '';
    const recipes = data.recipes || [];
    const discovered = recipes.filter((recipe) => recipe.discovered).length;

    document.getElementById('recipeCount').textContent = `${discovered}/${recipes.length} discovered`;

    recipes.forEach((recipe) => {
        const meta = [];
        meta.push(`<span class="pill">Level ${recipe.level}</span>`);
        if (recipe.requiredTierLabel) meta.push(`<span class="pill gold">${recipe.requiredTierLabel}</span>`);
        if (recipe.rare) meta.push('<span class="pill red">Rare</span>');

        list.appendChild(card(`
            <h3>${recipe.label}</h3>
            <p>${recipe.discovered ? recipe.ingredients : (recipe.lockReason || 'Undiscovered mixture')}</p>
            <div class="pill-row">${meta.join('')}</div>
        `, !recipe.discovered));
    });
}

function renderFruit(data) {
    const list = document.getElementById('fruitList');
    list.innerHTML = '';

    (data.fruits || []).forEach((fruit) => {
        const element = document.createElement('article');
        element.className = `fruit-card${fruit.unlocked ? '' : ' locked'}`;
        element.innerHTML = `
            <div class="silhouette"></div>
            <h3>${fruit.unlocked ? fruit.label : 'Locked Fruit'}</h3>
            <p class="meta">${fruit.unlocked ? 'Visible in the orchard' : `Unlocks at level ${fruit.minLevel}`}</p>
        `;
        list.appendChild(element);
    });
}

function renderTools(data) {
    const list = document.getElementById('toolsList');
    list.innerHTML = '';

    (data.tools || []).forEach((tool) => {
        list.appendChild(card(`
            <h3>${tool.label}</h3>
            <p>${tool.description}</p>
            <div class="pill-row">
                <span class="pill ${tool.owned ? '' : 'red'}">${tool.owned ? `Owned x${tool.count}` : 'Not carried'}</span>
            </div>
        `, !tool.owned));
    });
}

function render(data) {
    latestData = data;
    renderSummary(data);
    renderOrders(data);
    renderRecipes(data);
    renderFruit(data);
    renderTools(data);
}

function closeJournal(sendClose = true) {
    app.style.display = 'none';
    app.classList.add('hidden');
    if (sendClose) post('close');
}

closeButton.addEventListener('click', closeJournal);

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') closeJournal();
});

tabs.forEach((tab) => {
    tab.addEventListener('click', () => {
        tabs.forEach((item) => item.classList.remove('active'));
        pages.forEach((page) => page.classList.remove('active'));
        tab.classList.add('active');
        document.getElementById(tab.dataset.tab).classList.add('active');
    });
});

window.addEventListener('message', (event) => {
    const payload = event.data || {};
    if (payload.action === 'open') {
        app.style.display = 'flex';
        app.classList.remove('hidden');
        render(payload.data || {});
    }

    if (payload.action === 'refresh' && latestData) {
        render(payload.data || {});
    }

    if (payload.action === 'close') {
        closeJournal(false);
    }
});
