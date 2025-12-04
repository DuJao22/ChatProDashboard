

-- Schema do banco de dados SQLite3
-- Sistema Ariguá Distribuidora & Ponto D'Água
-- Desenvolvido por João Layon - Full Stack Developer

-- Tabela de usuários (admin)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    email TEXT,
    is_admin INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de clientes
CREATE TABLE IF NOT EXISTS customers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT UNIQUE,
    email TEXT,
    cep TEXT,
    address TEXT,
    number TEXT,
    complement TEXT,
    neighborhood TEXT,
    city TEXT,
    state TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Tabela de categorias
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de produtos
CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    price REAL NOT NULL,
    image_url TEXT,
    category_id INTEGER,
    stock INTEGER DEFAULT 0,
    active INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Tabela de variantes de produtos
CREATE TABLE IF NOT EXISTS product_variants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    price_modifier REAL DEFAULT 0,
    stock INTEGER DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Tabela de conversas
CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER,
    session_id TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- Tabela de mensagens
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id INTEGER NOT NULL,
    sender TEXT NOT NULL,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',
    metadata TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id)
);

-- Tabela de itens do carrinho
CREATE TABLE IF NOT EXISTS cart_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER,
    session_id TEXT,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    quantity INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(id)
);

-- Tabela de pedidos
CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    status TEXT DEFAULT 'pending',
    subtotal REAL NOT NULL,
    shipping REAL DEFAULT 0,
    discount REAL DEFAULT 0,
    total REAL NOT NULL,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'pending',
    shipping_address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- Tabela de itens do pedido
CREATE TABLE IF NOT EXISTS order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    quantity INTEGER NOT NULL,
    price REAL NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Tabela de logs de pedidos
CREATE TABLE IF NOT EXISTS order_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    status TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- Tabela de tokens de login
CREATE TABLE IF NOT EXISTS login_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    token TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- Tabela de cupons
CREATE TABLE IF NOT EXISTS coupons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT NOT NULL,
    discount_value REAL NOT NULL,
    min_value REAL DEFAULT 0,
    max_uses INTEGER,
    used_count INTEGER DEFAULT 0,
    active INTEGER DEFAULT 1,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de logs do sistema
CREATE TABLE IF NOT EXISTS system_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    message TEXT NOT NULL,
    data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de configurações
CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT UNIQUE NOT NULL,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de pedidos pendentes do chat (para persistir entre reconexões)
CREATE TABLE IF NOT EXISTS chat_pending_orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id INTEGER UNIQUE,
    customer_id INTEGER,
    items_json TEXT NOT NULL,
    total REAL NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(active);
CREATE INDEX IF NOT EXISTS idx_conversations_customer ON conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_session ON conversations(session_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_cart_customer ON cart_items(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_session ON cart_items(session_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);

-- Inserir admin padrão (senha: admin123)
-- Hash SHA256 de 'admin123'
INSERT OR IGNORE INTO users (username, password, email, is_admin) 
VALUES ('admin', 'c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd4', 'admin@arigua.com.br', 1);

-- Limpar dados antigos e inserir novos
DELETE FROM categories;
DELETE FROM products;

-- Categorias para Distribuidora de Água e Bebidas
INSERT INTO categories (id, name, description, active) VALUES 
(1, 'Água Mineral', 'Galões e garrafas de água mineral', 1),
(2, 'Refrigerantes', 'Refrigerantes de diversas marcas e sabores', 1),
(3, 'Sucos', 'Sucos naturais e industrializados', 1),
(4, 'Energéticos', 'Bebidas energéticas e isotônicos', 1);

-- Produtos de Distribuidora de Água e Bebidas
INSERT INTO products (id, name, description, price, category_id, stock, active, image_url) VALUES 
-- Água Mineral
(1, 'Galão de Água 20L', 'Galão de água mineral 20 litros - retornável', 12.00, 1, 500, 1, 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400'),
(2, 'Água Mineral 500ml', 'Garrafa de água mineral 500ml', 1.50, 1, 300, 1, 'https://images.unsplash.com/photo-1560023907-5f339617ea30?w=400'),
(3, 'Água Mineral 500ml (Pack 12un)', 'Pack com 12 garrafas de água mineral 500ml', 15.90, 1, 200, 1, 'https://images.unsplash.com/photo-1560023907-5f339617ea30?w=400'),
(4, 'Água Mineral 1,5L', 'Garrafa de água mineral 1,5 litros', 2.50, 1, 250, 1, 'https://images.unsplash.com/photo-1564419320461-6870880221ad?w=400'),
(5, 'Água Mineral 1,5L (Pack 6un)', 'Pack com 6 garrafas de água mineral 1,5 litros', 13.90, 1, 150, 1, 'https://images.unsplash.com/photo-1564419320461-6870880221ad?w=400'),
(6, 'Água com Gás 500ml', 'Garrafa de água com gás 500ml', 2.00, 1, 200, 1, 'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400'),
(7, 'Água com Gás 500ml (Pack 12un)', 'Pack com 12 garrafas de água com gás 500ml', 21.90, 1, 100, 1, 'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400'),

-- Refrigerantes
(8, 'Coca-Cola Lata 350ml', 'Lata individual de Coca-Cola 350ml', 3.50, 2, 400, 1, 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400'),
(9, 'Coca-Cola 350ml (Pack 12un)', 'Pack com 12 latas de Coca-Cola 350ml', 38.90, 2, 200, 1, 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400'),
(10, 'Coca-Cola 2L', 'Refrigerante Coca-Cola 2 litros', 9.90, 2, 300, 1, 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400'),
(11, 'Coca-Cola 2L (Pack 6un)', 'Pack com 6 garrafas de Coca-Cola 2 litros', 54.90, 2, 150, 1, 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400'),
(12, 'Guaraná Antarctica Lata 350ml', 'Lata individual de Guaraná Antarctica 350ml', 3.00, 2, 350, 1, 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400'),
(13, 'Guaraná Antarctica 350ml (Pack 12un)', 'Pack com 12 latas de Guaraná Antarctica 350ml', 33.90, 2, 180, 1, 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400'),
(14, 'Guaraná Antarctica 2L', 'Refrigerante Guaraná Antarctica 2 litros', 7.90, 2, 250, 1, 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400'),
(15, 'Fanta Laranja Lata 350ml', 'Lata individual de Fanta Laranja 350ml', 3.00, 2, 300, 1, 'https://images.unsplash.com/photo-1624517452488-04869289c4ca?w=400'),
(16, 'Fanta Laranja 2L', 'Refrigerante Fanta Laranja 2 litros', 7.90, 2, 200, 1, 'https://images.unsplash.com/photo-1624517452488-04869289c4ca?w=400'),
(17, 'Sprite Lata 350ml', 'Lata individual de Sprite 350ml', 3.00, 2, 280, 1, 'https://images.unsplash.com/photo-1625772452859-1c03d5ba1878?w=400'),
(18, 'Sprite 2L', 'Refrigerante Sprite 2 litros', 7.90, 2, 180, 1, 'https://images.unsplash.com/photo-1625772452859-1c03d5ba1878?w=400'),
(19, 'Pepsi 350ml (Pack 12un)', 'Pack com 12 latas de Pepsi 350ml', 33.90, 2, 150, 1, 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400'),
(20, 'Pepsi 2L', 'Refrigerante Pepsi 2 litros', 7.50, 2, 170, 1, 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400'),

-- Sucos
(21, 'Suco Del Valle Uva 1L', 'Suco Del Valle sabor Uva 1 litro', 6.50, 3, 180, 1, 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=400'),
(22, 'Suco Del Valle Uva 1L (Pack 6un)', 'Pack com 6 unidades de suco Del Valle Uva 1 litro', 35.90, 3, 120, 1, 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=400'),
(23, 'Suco Del Valle Laranja 1L', 'Suco Del Valle sabor Laranja 1 litro', 6.50, 3, 200, 1, 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400'),
(24, 'Suco Del Valle Laranja 1L (Pack 6un)', 'Pack com 6 unidades de suco Del Valle Laranja 1 litro', 35.90, 3, 130, 1, 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400'),
(25, 'Suco Del Valle Pêssego 1L', 'Suco Del Valle sabor Pêssego 1 litro', 6.50, 3, 150, 1, 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400'),
(26, 'Suco Natural One Laranja 900ml', 'Suco 100% natural de laranja Natural One 900ml', 12.90, 3, 80, 1, 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400'),
(27, 'Suco Natural One Uva 900ml', 'Suco 100% natural de uva Natural One 900ml', 12.90, 3, 75, 1, 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=400'),
(28, 'Água de Coco Sococo 1L', 'Água de coco Sococo 1 litro', 8.90, 3, 140, 1, 'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=400'),
(29, 'Água de Coco Sococo 1L (Pack 6un)', 'Pack com 6 unidades de água de coco Sococo 1 litro', 47.90, 3, 100, 1, 'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=400'),
(30, 'Néctar Maguary Manga 1L', 'Néctar de Manga Maguary 1 litro', 5.50, 3, 160, 1, 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400'),

-- Energéticos
(31, 'Red Bull 250ml', 'Lata de Red Bull 250ml', 10.90, 4, 200, 1, 'https://images.unsplash.com/photo-1527960471264-932f39eb5846?w=400'),
(32, 'Red Bull 250ml (Pack 6un)', 'Pack com 6 latas de Red Bull 250ml', 59.90, 4, 150, 1, 'https://images.unsplash.com/photo-1527960471264-932f39eb5846?w=400'),
(33, 'Monster Energy 473ml', 'Lata de Monster Energy 473ml', 11.90, 4, 180, 1, 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=400'),
(34, 'Monster Energy 473ml (Pack 6un)', 'Pack com 6 latas de Monster Energy 473ml', 65.90, 4, 120, 1, 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=400'),
(35, 'Gatorade 500ml', 'Garrafa de Gatorade 500ml sabores variados', 6.50, 4, 220, 1, 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=400'),
(36, 'Gatorade 500ml (Pack 6un)', 'Pack com 6 garrafas de Gatorade 500ml sabores variados', 35.90, 4, 100, 1, 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=400');
