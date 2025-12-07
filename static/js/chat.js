document.addEventListener('DOMContentLoaded', function() {
    const socket = io();
    const messagesContainer = document.getElementById('chatMessages');
    const messageInput = document.getElementById('messageInput');
    const sendBtn = document.getElementById('sendBtn');
    const typingIndicator = document.getElementById('typingIndicator');
    const menuBtn = document.getElementById('menuBtn');
    const headerMenu = document.getElementById('headerMenu');
    const quickActions = document.querySelectorAll('.quick-action-btn');

    let currentCategory = '';
    let productsVisible = false;

    function formatTimestamp(timestamp) {
        if (!timestamp) return '';
        
        const date = new Date(timestamp);
        const brasiliaOffset = -3 * 60;
        const localOffset = date.getTimezoneOffset();
        const diff = brasiliaOffset - localOffset;
        
        const brasiliaTime = new Date(date.getTime() + diff * 60000);
        
        const hours = String(brasiliaTime.getHours()).padStart(2, '0');
        const minutes = String(brasiliaTime.getMinutes()).padStart(2, '0');
        
        return `${hours}:${minutes}`;
    }

    socket.on('connect', function() {
        console.log('Connected to chat server');
    });

    socket.on('load_messages', function(messages) {
        messages.forEach(msg => addMessage(msg.sender, msg.content, msg.created_at, true));
        scrollToBottom();
    });

    socket.on('message', function(data) {
        hideTyping();
        addMessage(data.sender, data.content, data.timestamp, false);
        scrollToBottom();
        
        // Verificar se deve mostrar produtos após adicionar a mensagem
        if (data.sender === 'bot' && data.content.includes('[SHOW_PRODUCTS]')) {
            setTimeout(() => {
                loadAndShowProducts();
                scrollToBottom();
            }, 300);
        }
    });

    // Prevenir múltiplas conexões
    socket.on('connect', function() {
        console.log('✅ Conectado ao chat');
    });

    socket.on('disconnect', function() {
        console.log('❌ Desconectado do chat');
    });

    socket.on('connect_error', function(error) {
        console.error('❌ Erro de conexão:', error);
    });

    function addMessage(sender, content, timestamp, isHistorical = false) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${sender}`;
        
        const time = timestamp ? formatTimestamp(timestamp) : '';
        
        let displayContent = content;
        let shouldRedirect = false;
        let shouldShowProducts = false;
        
        if (sender === 'bot') {
            if (content.includes('[redirect:loja]')) {
                displayContent = content.replace('[redirect:loja]', '');
                if (!isHistorical) {
                    shouldRedirect = true;
                }
            }
            
            if (content.includes('[SHOW_PRODUCTS]')) {
                displayContent = content.replace('[SHOW_PRODUCTS]', '').trim();
                if (!isHistorical) {
                    shouldShowProducts = true;
                }
            }
        }
        
        // Só adicionar mensagem se tiver conteúdo após remover as tags
        if (displayContent) {
            messageDiv.innerHTML = `
                <div class="message-bubble">
                    <div class="message-content">${escapeHtml(displayContent)}</div>
                    <div class="message-time">${time}</div>
                </div>
            `;
            
            messagesContainer.appendChild(messageDiv);
        }
        
        if (shouldRedirect) {
            setTimeout(() => {
                window.location.href = '/loja';
            }, 2000);
        }
        
        if (shouldShowProducts) {
            setTimeout(() => {
                loadAndShowProducts();
                scrollToBottom();
            }, 300);
        }
    }

    function loadAndShowProducts(category = '') {
        currentCategory = category;
        productsVisible = true;
        
        fetch(`/api/chat/products?category=${category}`)
            .then(response => response.json())
            .then(data => {
                renderProductsInChat(data.products, data.categories);
                scrollToBottom();
            })
            .catch(err => console.error('Error loading products:', err));
    }

    function renderProductsInChat(products, categories) {
        const existingProductsContainer = document.querySelector('.chat-products-container');
        if (existingProductsContainer) {
            existingProductsContainer.remove();
        }

        const productsContainer = document.createElement('div');
        productsContainer.className = 'chat-products-container';
        
        let categoriesHtml = `
            <div class="chat-categories-scroll">
                <div class="chat-categories">
                    <button class="chat-category-btn ${currentCategory === '' ? 'active' : ''}" data-category="">
                        <i class="fas fa-th-large"></i> Todos
                    </button>
        `;
        
        categories.forEach(cat => {
            categoriesHtml += `
                <button class="chat-category-btn ${currentCategory == cat.id ? 'active' : ''}" data-category="${cat.id}">
                    <i class="fas fa-tag"></i> ${cat.name}
                </button>
            `;
        });
        
        categoriesHtml += '</div></div>';

        let productsHtml = '<div class="chat-products-grid">';
        
        products.forEach(product => {
            const imageUrl = product.image_url || 'https://via.placeholder.com/150x150?text=Produto';
            productsHtml += `
                <div class="chat-product-card" data-id="${product.id}">
                    <div class="chat-product-image">
                        <img src="${imageUrl}" alt="${product.name}" loading="lazy">
                    </div>
                    <div class="chat-product-info">
                        <span class="chat-product-category">${product.category_name || 'Geral'}</span>
                        <h4 class="chat-product-name">${product.name}</h4>
                        <div class="chat-product-footer">
                            <span class="chat-product-price">R$ ${parseFloat(product.price).toFixed(2).replace('.', ',')}</span>
                            <button class="chat-add-btn" data-id="${product.id}" data-name="${product.name}" ${product.stock === 0 ? 'disabled' : ''}>
                                <i class="fas fa-plus"></i>
                            </button>
                        </div>
                    </div>
                </div>
            `;
        });
        
        productsHtml += '</div>';

        const finishOrderHtml = `
            <div class="chat-finish-order">
                <button class="finish-order-btn" onclick="window.location.href='/carrinho'">
                    <i class="fas fa-shopping-cart"></i>
                    Finalizar Pedido
                    <span class="finish-order-badge" id="finishOrderBadge">0</span>
                </button>
            </div>
        `;
        
        productsContainer.innerHTML = categoriesHtml + productsHtml + finishOrderHtml;
        messagesContainer.appendChild(productsContainer);

        productsContainer.querySelectorAll('.chat-category-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const category = this.dataset.category;
                loadAndShowProducts(category);
            });
        });

        productsContainer.querySelectorAll('.chat-add-btn').forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.stopPropagation();
                const productId = this.dataset.id;
                const productName = this.dataset.name;
                addToCart(productId, productName);
            });
        });

        updateFinishOrderBadge();
    }

    function addToCart(productId, productName) {
        fetch('/api/cart', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                product_id: productId,
                quantity: 1
            })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showToast(`${productName} adicionado!`);
                updateCartBadge();
                updateFinishOrderBadge();
            }
        })
        .catch(err => console.error('Error adding to cart:', err));
    }

    function updateFinishOrderBadge() {
        fetch('/api/cart')
            .then(response => response.json())
            .then(items => {
                const count = items.reduce((total, item) => total + item.quantity, 0);
                const badge = document.getElementById('finishOrderBadge');
                if (badge) {
                    badge.textContent = count;
                    badge.style.display = count > 0 ? 'flex' : 'none';
                }
            })
            .catch(err => console.error('Error loading cart:', err));
    }

    function showToast(message) {
        const toast = document.getElementById('toast');
        const toastMessage = document.getElementById('toastMessage');
        if (toast && toastMessage) {
            toastMessage.textContent = message;
            toast.classList.add('show');
            setTimeout(() => {
                toast.classList.remove('show');
            }, 2000);
        }
    }

    function sendMessage() {
        const content = messageInput.value.trim();
        if (!content) return;
        
        socket.emit('message', { content: content });
        messageInput.value = '';
        showTyping();
    }

    function showTyping() {
        typingIndicator.classList.add('show');
        scrollToBottom();
    }

    function hideTyping() {
        typingIndicator.classList.remove('show');
    }

    function scrollToBottom() {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        let html = div.innerHTML;
        
        html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        html = html.replace(/\*(.*?)\*/g, '<strong>$1</strong>');
        html = html.replace(/_(.*?)_/g, '<em>$1</em>');
        html = html.replace(/\n/g, '<br>');
        html = html.replace(/^([•●○▪▫])/gm, '<span style="color: #667eea;">$1</span>');
        
        return html;
    }

    sendBtn.addEventListener('click', sendMessage);
    
    messageInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            sendMessage();
        }
    });

    messageInput.addEventListener('focus', function() {
        setTimeout(scrollToBottom, 300);
    });

    menuBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        headerMenu.classList.toggle('show');
    });

    document.addEventListener('click', function(e) {
        if (!headerMenu.contains(e.target)) {
            headerMenu.classList.remove('show');
        }
    });

    quickActions.forEach(btn => {
        btn.addEventListener('click', function() {
            const message = this.dataset.message;
            messageInput.value = message;
            sendMessage();
        });
    });

    const clearChatBtn = document.getElementById('clearChatBtn');
    if (clearChatBtn) {
        clearChatBtn.addEventListener('click', function(e) {
            e.preventDefault();
            if (confirm('Tem certeza que deseja limpar o chat?')) {
                const messages = messagesContainer.querySelectorAll('.message, .chat-products-container');
                messages.forEach(msg => msg.remove());
                
                const dateDiv = document.createElement('div');
                dateDiv.className = 'chat-date';
                dateDiv.innerHTML = '<span>Hoje</span>';
                messagesContainer.appendChild(dateDiv);
                
                headerMenu.classList.remove('show');
                productsVisible = false;
                
                socket.disconnect();
                socket.connect();
            }
        });
    }

    updateCartBadge();
});

function updateCartBadge() {
    fetch('/api/cart')
        .then(response => response.json())
        .then(items => {
            const count = items.reduce((total, item) => total + item.quantity, 0);
            const badge = document.getElementById('cartBadge');
            if (badge) {
                badge.textContent = count;
                badge.style.display = count > 0 ? 'flex' : 'none';
            }
        })
        .catch(err => console.error('Error loading cart:', err));
}
