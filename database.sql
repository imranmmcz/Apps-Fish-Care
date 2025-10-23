-- Fish Care Database Schema
-- Create Database
CREATE DATABASE IF NOT EXISTS fishcare_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fishcare_db;

-- Users Table
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_type ENUM('farmer', 'seller', 'wholesaler') NOT NULL,
    name VARCHAR(100) NOT NULL,
    mobile VARCHAR(15) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    division VARCHAR(50),
    district VARCHAR(50),
    upazila VARCHAR(50),
    address TEXT,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_mobile (mobile),
    INDEX idx_user_type (user_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Fish Types Table
CREATE TABLE fish_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name_bn VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    description TEXT,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Market Rates Table
CREATE TABLE market_rates (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fish_type_id INT NOT NULL,
    division VARCHAR(50) NOT NULL,
    district VARCHAR(50) NOT NULL,
    upazila VARCHAR(50),
    size ENUM('small', 'medium', 'large') NOT NULL,
    price_per_kg DECIMAL(10,2) NOT NULL,
    min_price DECIMAL(10,2),
    max_price DECIMAL(10,2),
    price_change_percent DECIMAL(5,2),
    date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fish_type_id) REFERENCES fish_types(id),
    INDEX idx_location (division, district, upazila),
    INDEX idx_date (date),
    INDEX idx_fish_type (fish_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ponds/Farms Table
CREATE TABLE ponds (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    size_decimal DECIMAL(10,2) COMMENT 'Size in decimal',
    water_depth DECIMAL(5,2) COMMENT 'Depth in feet',
    location TEXT,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stock/Inventory Table
CREATE TABLE stock (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    pond_id INT,
    fish_type_id INT NOT NULL,
    size ENUM('small', 'medium', 'large') NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,
    average_weight DECIMAL(5,2) COMMENT 'Average weight per piece in kg',
    price_per_kg DECIMAL(10,2) NOT NULL,
    total_value DECIMAL(12,2) NOT NULL,
    location VARCHAR(100),
    date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (pond_id) REFERENCES ponds(id) ON DELETE SET NULL,
    FOREIGN KEY (fish_type_id) REFERENCES fish_types(id),
    INDEX idx_user (user_id),
    INDEX idx_fish_type (fish_type_id),
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Transactions (Income/Expense) Table
CREATE TABLE transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    pond_id INT,
    transaction_type ENUM('income', 'expense') NOT NULL,
    category VARCHAR(50) NOT NULL COMMENT 'fish_sale, fish_purchase, feed, medicine, labor, etc',
    amount DECIMAL(12,2) NOT NULL,
    description TEXT,
    transaction_date DATE NOT NULL,
    balance DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (pond_id) REFERENCES ponds(id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_date (transaction_date),
    INDEX idx_type (transaction_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Invoices Table
CREATE TABLE invoices (
    id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_mobile VARCHAR(15),
    customer_address TEXT,
    subtotal DECIMAL(12,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(12,2) NOT NULL,
    payment_status ENUM('paid', 'unpaid', 'partial') DEFAULT 'unpaid',
    invoice_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_invoice_number (invoice_number),
    INDEX idx_date (invoice_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Invoice Items Table
CREATE TABLE invoice_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_id INT NOT NULL,
    fish_type_id INT NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,
    price_per_kg DECIMAL(10,2) NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    FOREIGN KEY (fish_type_id) REFERENCES fish_types(id),
    INDEX idx_invoice (invoice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sales Table
CREATE TABLE sales (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    invoice_id INT,
    fish_type_id INT NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,
    price_per_kg DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    cost_per_kg DECIMAL(10,2),
    profit DECIMAL(12,2),
    sale_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    FOREIGN KEY (fish_type_id) REFERENCES fish_types(id),
    INDEX idx_user (user_id),
    INDEX idx_date (sale_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reports Summary Table
CREATE TABLE reports_summary (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    report_type ENUM('daily', 'weekly', 'monthly', 'yearly') NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    total_sales DECIMAL(12,2) DEFAULT 0,
    total_expenses DECIMAL(12,2) DEFAULT 0,
    net_profit DECIMAL(12,2) DEFAULT 0,
    profit_percentage DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_period (period_start, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert Sample Fish Types
INSERT INTO fish_types (name_bn, name_en) VALUES
('রুই মাছ', 'Rohu'),
('কাতলা মাছ', 'Catla'),
('পাংগাস মাছ', 'Pangasius'),
('তেলাপিয়া', 'Tilapia'),
('শিং মাছ', 'Stinging Catfish'),
('মাগুর মাছ', 'Walking Catfish'),
('সিলভার কার্প', 'Silver Carp'),
('গ্রাস কার্প', 'Grass Carp'),
('মৃগেল মাছ', 'Mrigal'),
('চিংড়ি', 'Prawn');

-- Insert Sample User (Password: 123456 - hashed)
INSERT INTO users (user_type, name, mobile, password, division, district, upazila) VALUES
('farmer', 'করিম মিয়া', '01711111111', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ঢাকা', 'ঢাকা', 'সাভার'),
('seller', 'রহিম উদ্দিন', '01722222222', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ঢাকা', 'ঢাকা', 'মিরপুর'),
('wholesaler', 'আব্দুল্লাহ', '01733333333', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'চট্টগ্রাম', 'চট্টগ্রাম', 'পটিয়া');

-- Insert Sample Market Rates
INSERT INTO market_rates (fish_type_id, division, district, upazila, size, price_per_kg, min_price, max_price, price_change_percent, date) VALUES
(1, 'ঢাকা', 'ঢাকা', 'সাভার', 'large', 200.00, 180.00, 220.00, 5.00, CURDATE()),
(2, 'ঢাকা', 'ঢাকা', 'সাভার', 'medium', 180.00, 160.00, 200.00, -3.00, CURDATE()),
(3, 'ঢাকা', 'ঢাকা', 'সাভার', 'large', 150.00, 140.00, 160.00, 2.00, CURDATE()),
(4, 'ঢাকা', 'ঢাকা', 'সাভার', 'medium', 120.00, 110.00, 130.00, 0.00, CURDATE()),
(5, 'ঢাকা', 'ঢাকা', 'সাভার', 'small', 300.00, 280.00, 320.00, 8.00, CURDATE());