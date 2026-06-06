const app = document.getElementById('app');
const itemsGrid = document.getElementById('itemsGrid');
const closeBtn = document.getElementById('closeBtn');
const searchInput = document.getElementById('searchInput');
const shopTitle = document.getElementById('shopTitle');
const shopSubtitle = document.getElementById('shopSubtitle');
const shopDescription = document.getElementById('shopDescription');

const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ScriptCore-BlackMarket';

let shop = {};
let items = [];
let itemCards = [];
let searchTimer = null;
let toastTimer = null;
let busy = false;

function postNui(event, data = {}) {
    return fetch(`https://${resourceName}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).then((response) => response.json()).catch(() => ({ ok: false, message: 'Ingen forbindelse til serveren.' }));
}

function safeText(value) {
    return String(value ?? '');
}

function iconClass(icon) {
    if (!icon) return 'fa-solid fa-box-open';
    if (icon.includes('fa-')) return icon.includes('fa-solid') ? icon : `fa-solid ${icon}`;
    return 'fa-solid fa-box-open';
}

function imageUrl(item) {
    if (item.image) return `nui://ox_inventory/web/images/${item.image}`;
    if (item.item) return `nui://ox_inventory/web/images/${item.item}.png`;
    return '';
}

function money(value) {
    return new Intl.NumberFormat('da-DK').format(Number(value) || 0);
}

function toast(message, type = 'inform') {
    let el = document.querySelector('.toast');
    if (!el) {
        el = document.createElement('div');
        el.className = 'toast';
        document.body.appendChild(el);
    }

    el.className = `toast ${type}`;
    el.textContent = message;

    clearTimeout(toastTimer);
    requestAnimationFrame(() => el.classList.add('show'));

    toastTimer = setTimeout(() => {
        el.classList.remove('show');
    }, 2600);
}

function createCard(item) {
    const card = document.createElement('article');
    card.className = 'market-card';
    card.dataset.search = `${item.label || ''} ${item.item || ''} ${item.description || ''}`.toLowerCase();

    const icon = document.createElement('div');
    icon.className = 'item-icon';

    const img = imageUrl(item);
    if (img) {
        const image = document.createElement('img');
        image.src = img;
        image.loading = 'lazy';
        image.onerror = () => {
            icon.textContent = '';
            const fallback = document.createElement('i');
            fallback.className = iconClass(item.icon);
            icon.appendChild(fallback);
        };
        icon.appendChild(image);
    } else {
        const fallback = document.createElement('i');
        fallback.className = iconClass(item.icon);
        icon.appendChild(fallback);
    }

    const info = document.createElement('div');
    info.className = 'item-info';

    const headline = document.createElement('div');
    headline.className = 'item-headline';

    const title = document.createElement('h2');
    title.textContent = safeText(item.label || item.item || 'Ukendt vare');

    headline.append(title);

    const desc = document.createElement('p');
    desc.textContent = safeText(item.description || '');

    const price = document.createElement('span');
    price.className = 'price';
    price.innerHTML = `<i class="fa-solid fa-coins"></i>${money(item.price)} ${safeText(shop.currencyLabel || 'DKK')}`;

    if (desc.textContent) info.append(headline, desc, price);
    else info.append(headline, price);

    const buy = document.createElement('div');
    buy.className = 'buy-area';
    buy.innerHTML = `
        <label>Antal</label>
        <input type="number" min="1" max="100" value="1" />
        <button class="buy-btn">Køb</button>
    `;

    const input = buy.querySelector('input');
    const button = buy.querySelector('.buy-btn');

    button.addEventListener('click', async () => {
        if (busy) return;

        const amount = Math.max(1, Math.min(100, Number(input.value) || 1));
        busy = true;
        button.disabled = true;
        button.textContent = '...';

        const result = await postNui('buyItem', { item: item.item, amount });
        toast(result.message || (result.ok ? 'Købt.' : 'Fejl.'), result.ok ? 'success' : 'error');

        busy = false;
        button.disabled = false;
        button.textContent = 'Køb';
    });

    card.append(icon, info, buy);
    return card;
}

function buildItems() {
    itemsGrid.textContent = '';
    itemCards = items.map(createCard);

    const fragment = document.createDocumentFragment();
    itemCards.forEach((card) => fragment.appendChild(card));
    itemsGrid.appendChild(fragment);
}

function filterItems() {
    const query = searchInput.value.toLowerCase().trim();
    let visible = 0;

    itemCards.forEach((card) => {
        const show = !query || card.dataset.search.includes(query);
        card.hidden = !show;
        if (show) visible += 1;
    });

    let empty = itemsGrid.querySelector('.empty');
    if (!visible) {
        if (!empty) {
            empty = document.createElement('div');
            empty.className = 'empty';
            empty.textContent = 'Ingen varer fundet.';
            itemsGrid.appendChild(empty);
        }
    } else if (empty) {
        empty.remove();
    }
}

function openUi(data) {
    shop = data.shop || {};
    items = Array.isArray(data.items) ? data.items : [];

    shopTitle.textContent = shop.title || 'Black Market';
    if (typeof shopSubtitle !== 'undefined' && shopSubtitle) shopSubtitle.textContent = shop.subtitle || '';
    if (typeof shopDescription !== 'undefined' && shopDescription) shopDescription.textContent = shop.description || '';
    searchInput.value = '';
    busy = false;

    buildItems();
    app.classList.remove('hidden');

    setTimeout(() => searchInput.focus(), 40);
}

function closeUi() {
    app.classList.add('hidden');
    busy = false;
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') openUi(data);
    if (data.action === 'close') closeUi();
});

closeBtn.addEventListener('click', () => postNui('close'));

searchInput.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(filterItems, 80);
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') postNui('close');
});
