-- ============================================================
-- СПРАВОЧНИКИ
-- ============================================================

-- Страны
INSERT INTO dim_country (country_name)
SELECT DISTINCT country FROM (
    SELECT customer_country AS country FROM mock_data WHERE customer_country IS NOT NULL
    UNION
    SELECT seller_country               FROM mock_data WHERE seller_country   IS NOT NULL
    UNION
    SELECT store_country                FROM mock_data WHERE store_country    IS NOT NULL
    UNION
    SELECT supplier_country             FROM mock_data WHERE supplier_country IS NOT NULL
) t ON CONFLICT DO NOTHING;

-- Города магазинов
INSERT INTO dim_city (city_name, state_name, country_id)
SELECT DISTINCT
    m.store_city,
    m.store_state,
    c.country_id
FROM mock_data m
JOIN dim_country c ON c.country_name = m.store_country
WHERE m.store_city IS NOT NULL
ON CONFLICT DO NOTHING;

-- Города поставщиков
INSERT INTO dim_city (city_name, state_name, country_id)
SELECT DISTINCT
    m.supplier_city,
	NULL,
    c.country_id
FROM mock_data m
JOIN dim_country c ON c.country_name = m.supplier_country
WHERE m.supplier_city IS NOT NULL
ON CONFLICT DO NOTHING;

-- Категории товаров
INSERT INTO dim_product_category (category_name)
SELECT DISTINCT product_category
FROM mock_data
WHERE product_category IS NOT NULL
ON CONFLICT DO NOTHING;

-- Бренды
INSERT INTO dim_brand (brand_name)
SELECT DISTINCT product_brand
FROM mock_data
WHERE product_brand IS NOT NULL
ON CONFLICT DO NOTHING;

-- Породы питомцев
INSERT INTO dim_pet_breed (breed_name)
SELECT DISTINCT customer_pet_breed
FROM mock_data
WHERE customer_pet_breed IS NOT NULL
ON CONFLICT DO NOTHING;


-- ============================================================
-- ИЗМЕРЕНИЯ
-- ============================================================

-- Питомцы
INSERT INTO dim_pet (pet_name, pet_type, pet_category, breed_id)
SELECT DISTINCT
    m.customer_pet_name,
    m.customer_pet_type,
    m.pet_category,
    b.breed_id
FROM mock_data m
JOIN dim_pet_breed b ON b.breed_name = m.customer_pet_breed
WHERE m.customer_pet_name IS NOT NULL;

-- Покупатели
INSERT INTO dim_customer (first_name, last_name, age, email, postal_code, country_id, pet_id)
SELECT DISTINCT ON (m.customer_email)
    m.customer_first_name,
    m.customer_last_name,
    m.customer_age,
    m.customer_email,
    m.customer_postal_code,
    c.country_id,
    p.pet_id
FROM mock_data m
JOIN dim_country c ON c.country_name = m.customer_country
LEFT JOIN dim_pet p ON p.pet_name    = m.customer_pet_name
                   AND p.pet_type    = m.customer_pet_type
ON CONFLICT DO NOTHING;

-- Продавцы
INSERT INTO dim_seller (first_name, last_name, email, postal_code, country_id)
SELECT DISTINCT ON (m.seller_email)
    m.seller_first_name,
    m.seller_last_name,
    m.seller_email,
    m.seller_postal_code,
    c.country_id
FROM mock_data m
JOIN dim_country c ON c.country_name = m.seller_country
WHERE m.seller_email IS NOT NULL
ON CONFLICT DO NOTHING;

-- Поставщики
INSERT INTO dim_supplier (supplier_name, contact_name, email, phone, address, city_id)
SELECT DISTINCT ON (m.supplier_name, m.supplier_email)
    m.supplier_name,
    m.supplier_contact,
    m.supplier_email,
    m.supplier_phone,
    m.supplier_address,
    ci.city_id
FROM mock_data m
LEFT JOIN dim_city ci ON ci.city_name = m.supplier_city
ON CONFLICT DO NOTHING;

-- Товары
INSERT INTO dim_product (product_name, price, weight, color, size, material,
                         description, rating, reviews, release_date, expiry_date,
                         category_id, brand_id, supplier_id)
SELECT DISTINCT ON (m.product_name, m.product_price)
    m.product_name,
    m.product_price,
    m.product_weight,
    m.product_color,
    m.product_size,
    m.product_material,
    m.product_description,
    m.product_rating,
    m.product_reviews,
    TO_DATE(m.product_release_date, 'MM/DD/YYYY'),
    TO_DATE(m.product_expiry_date,  'MM/DD/YYYY'),
    pc.category_id,
    br.brand_id,
    su.supplier_id
FROM mock_data m
JOIN dim_product_category pc ON pc.category_name = m.product_category
JOIN dim_brand            br ON br.brand_name     = m.product_brand
JOIN dim_supplier         su ON su.supplier_name  = m.supplier_name
ON CONFLICT DO NOTHING;

-- Магазины
INSERT INTO dim_store (store_name, location, phone, email, city_id)
SELECT DISTINCT ON (m.store_name, m.store_email)
    m.store_name,
    m.store_location,
    m.store_phone,
    m.store_email,
    ci.city_id
FROM mock_data m
LEFT JOIN dim_city ci ON ci.city_name = m.store_city
ON CONFLICT DO NOTHING;

-- Дата
INSERT INTO dim_date (full_date, day, month, quarter, year, weekday)
SELECT DISTINCT
    TO_DATE(sale_date, 'MM/DD/YYYY'),
    EXTRACT(DAY     FROM TO_DATE(sale_date, 'MM/DD/YYYY'))::INT,
    EXTRACT(MONTH   FROM TO_DATE(sale_date, 'MM/DD/YYYY'))::INT,
    EXTRACT(QUARTER FROM TO_DATE(sale_date, 'MM/DD/YYYY'))::INT,
    EXTRACT(YEAR    FROM TO_DATE(sale_date, 'MM/DD/YYYY'))::INT,
    TO_CHAR(TO_DATE(sale_date, 'MM/DD/YYYY'), 'Day')
FROM mock_data
WHERE sale_date IS NOT NULL
ON CONFLICT DO NOTHING;


-- ============================================================
-- ФАКТ
-- ============================================================

INSERT INTO fact_sales (date_id, customer_id, seller_id, product_id, store_id,
                        sale_quantity, sale_total_price)
SELECT
    d.date_id,
    cu.customer_id,
    se.seller_id,
    pr.product_id,
    st.store_id,
    m.sale_quantity,
    m.sale_total_price
FROM mock_data m
JOIN dim_date     d  ON d.full_date     = TO_DATE(m.sale_date, 'MM/DD/YYYY')
JOIN dim_customer cu ON cu.email        = m.customer_email
JOIN dim_seller   se ON se.email        = m.seller_email
JOIN dim_product  pr ON pr.product_name = m.product_name
                    AND pr.price        = m.product_price
JOIN dim_store    st ON st.store_name   = m.store_name;
