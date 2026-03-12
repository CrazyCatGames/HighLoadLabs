-- ============================================================
-- СПРАВОЧНИКИ
-- ============================================================
-- Страна
CREATE TABLE dim_country (
    country_id   SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE
);

-- Город
CREATE TABLE dim_city (
    city_id    SERIAL PRIMARY KEY,
    city_name  VARCHAR(100) NOT NULL,
	state_name VARCHAR(100),
    country_id INT NOT NULL REFERENCES dim_country(country_id),
    UNIQUE (city_name, country_id)
);

-- Категория продуктов
CREATE TABLE dim_product_category (
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

-- Бренд
CREATE TABLE dim_brand (
    brand_id   SERIAL PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE
);

-- Порода
CREATE TABLE dim_pet_breed (
    breed_id   SERIAL PRIMARY KEY,
    breed_name VARCHAR(100) NOT NULL UNIQUE 
);


-- ============================================================
-- ИЗМЕРЕНИЯ
-- ============================================================

-- Питомец покупателя
CREATE TABLE dim_pet (
    pet_id       SERIAL PRIMARY KEY,
    pet_name     VARCHAR(100),
    pet_type     VARCHAR(50),
    pet_category VARCHAR(100),
    breed_id     INT REFERENCES dim_pet_breed(breed_id)
);

-- Покупатель
CREATE TABLE dim_customer (
    customer_id  SERIAL PRIMARY KEY,
    first_name   VARCHAR(100),
    last_name    VARCHAR(100),
    age          INT,
    email        VARCHAR(200) UNIQUE,
    postal_code  VARCHAR(20),
    country_id   INT REFERENCES dim_country(country_id),
    pet_id       INT REFERENCES dim_pet(pet_id)
);

-- Продавец
CREATE TABLE dim_seller (
    seller_id   SERIAL PRIMARY KEY,
    first_name  VARCHAR(100),
    last_name   VARCHAR(100),
    email       VARCHAR(200) UNIQUE,
    postal_code VARCHAR(20),
    country_id  INT REFERENCES dim_country(country_id)
);

-- Поставщик
CREATE TABLE dim_supplier (
    supplier_id  SERIAL PRIMARY KEY,
    supplier_name VARCHAR(200),
    contact_name  VARCHAR(200),
    email         VARCHAR(200),
    phone         VARCHAR(50),
    address       VARCHAR(200),
    city_id       INT REFERENCES dim_city(city_id),
    UNIQUE (supplier_name, email)
);

-- Товар
CREATE TABLE dim_product (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(200),
    price        NUMERIC(10,2),
    weight       NUMERIC(10,2),
    color        VARCHAR(50),
    size         VARCHAR(50),
    material     VARCHAR(100),
    description  TEXT,
    rating       NUMERIC(3,1),
    reviews      INT,
    release_date DATE,
    expiry_date  DATE,
    category_id  INT REFERENCES dim_product_category(category_id),
    brand_id     INT REFERENCES dim_brand(brand_id),
    supplier_id  INT REFERENCES dim_supplier(supplier_id),
    UNIQUE (product_name, price)
);

-- Магазин
CREATE TABLE dim_store (
    store_id   SERIAL PRIMARY KEY,
    store_name VARCHAR(200),
    location   VARCHAR(200),
    phone      VARCHAR(50),
    email      VARCHAR(200),
    city_id    INT REFERENCES dim_city(city_id),
    UNIQUE (store_name, email)
);

-- Дата
CREATE TABLE dim_date (
    date_id   SERIAL PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day       INT,
    month     INT,
    quarter   INT,
    year      INT,
    weekday   VARCHAR(20)
);


-- ============================================================
-- ФАКТ ПРОДАЖ
-- ============================================================

CREATE TABLE fact_sales (
    sale_id          SERIAL PRIMARY KEY,
    date_id          INT NOT NULL REFERENCES dim_date(date_id),
    customer_id      INT NOT NULL REFERENCES dim_customer(customer_id),
    seller_id        INT NOT NULL REFERENCES dim_seller(seller_id),
    product_id       INT NOT NULL REFERENCES dim_product(product_id),
    store_id         INT NOT NULL REFERENCES dim_store(store_id),
    sale_quantity    INT,
    sale_total_price NUMERIC(10,2)
);