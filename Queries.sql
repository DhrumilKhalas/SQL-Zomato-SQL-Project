


-- (1) What is the total amount each customer spent on Zomato?

SELECT
    a.userid,
    SUM(b.price) total_amount_spent
FROM
    sales a
    INNER JOIN product b ON a.product_id = b.product_id
GROUP BY
    userid


-- (2) How many days has each customer visited Zomato?

SELECT
    userid,
    COUNT(DISTINCT created_date) distinct_days
FROM
    sales
GROUP BY
    userid


-- (3) What was the first product purchased by each customer?

SELECT
    *
FROM
    (
        SELECT
            *,
            RANK() OVER(
                PARTITION BY userid
                ORDER BY
                    created_date
            ) rnk
        FROM
            sales
    ) a
WHERE
    rnk = 1


-- (4) What is the most purchased item on the menu, and how many times was it purchased by all customers?

SELECT
    userid,
    COUNT(product_id) cnt
FROM
    sales
WHERE
    product_id = (
        SELECT
            product_id
        FROM
            sales
        GROUP BY
            product_id
        ORDER BY
            COUNT(product_id) desc
        LIMIT
            1
    )
GROUP BY
    userid


-- (5) Which item was the most popular for each customer?

SELECT
    *
FROM
    (
        SELECT
            *,
            RANK() OVER(
                PARTITION BY userid
                ORDER BY
                    cnt desc
            ) rnk
        FROM
            (
                SELECT
                    userid,
                    product_id,
                    COUNT(product_id) cnt
                FROM
                    sales
                GROUP BY
                    userid,
                    product_id
            ) a
    ) b
WHERE
    rnk = 1


-- (6) Which item was purchased first by the customer after becoming a member?

SELECT
    *
FROM
    (
        SELECT
            c.*,
            RANK() OVER(
                PARTITION BY userid
                ORDER BY
                    created_date asc
            ) rnk
        FROM
            (
                SELECT
                    a.userid,
                    a.created_date,
                    a.product_id,
                    b.gold_signup_date
                FROM
                    sales a
                    INNER JOIN goldusers_signup b ON a.userid = b.userid
                    AND created_date >= gold_signup_date
            ) c
    )
WHERE
    rnk = 1;


-- (7) Which item was purchased just before the customer became a member?

SELECT
    *
FROM
    (
        SELECT
            c.*,
            RANK() OVER(
                PARTITION BY userid
                ORDER BY
                    created_date desc
            ) rnk
        FROM
            (
                SELECT
                    a.userid,
                    a.created_date,
                    a.product_id,
                    b.gold_signup_date
                FROM
                    sales a
                    INNER JOIN goldusers_signup b ON a.userid = b.userid
                    AND created_date <= gold_signup_date
            ) c
    )
WHERE
    rnk = 1;


-- (8) What are the total orders and the amount spent for each member before they became a member?

SELECT
    userid,
    COUNT(created_date) order_purchased,
    SUM(price) total_amt_spent
FROM
    (
        SELECT
            c.*,
            d.price
        FROM
            (
                SELECT
                    a.userid,
                    a.created_date,
                    a.product_id,
                    b.gold_signup_date
                FROM
                    sales a
                    INNER JOIN goldusers_signup b ON a.userid = b.userid
                    AND created_date <= gold_signup_date
            ) c
            INNER JOIN product d ON c.product_id = d.product_id
    )
GROUP BY
    userid;


-- (9) For each customer, calculate the total Zomato points collected based on their purchases, considering a conversion rate of 5 rs = 2 Zomato points. Each product has a different purchasing point rate; for example, p1 has a rate of 5 rs = 1 point, p2 has a rate of 10 rs = 5 points, and p3 has a rate of 5 rs = 1 point. Determine which product has contributed the most points overall."

SELECT
    userid,
    SUM(total_points) total_points_earned,
    SUM(total_points) * 2.5 total_money_earned
FROM
    (
        SELECT
            e.*,
            amt / points total_points
        FROM
            (
                SELECT
                    d.*,
                    CASE
                        WHEN product_id = 1 THEN 5
                        WHEN product_id = 2 THEN 2
                        WHEN product_id = 3 THEN 5
                        ELSE 0
                    END AS points
                FROM
                    (
                        SELECT
                            c.userid,
                            c.product_id,
                            SUM(price) amt
                        FROM
                            (
                                SELECT
                                    a.*,
                                    b.price
                                FROM
                                    sales a
                                    INNER JOIN product b ON a.product_id = b.product_id
                            ) c
                        GROUP BY
                            userid,
                            product_id
                    ) d
            ) e
    ) f
GROUP BY
    userid
ORDER BY
    userid

SELECT
    *
FROM
    (
        SELECT
            *,
            RANK() OVER(
                ORDER BY
                    total_point_earned desc
            ) rnk
        FROM
            (
                SELECT
                    product_id,
                    SUM(total_points) total_point_earned
                FROM
                    (
                        SELECT
                            e.*,
                            amt / points total_points
                        FROM
                            (
                                SELECT
                                    d.*,
                                    CASE
                                        WHEN product_id = 1 THEN 5
                                        WHEN product_id = 2 THEN 2
                                        WHEN product_id = 3 THEN 5
                                        ELSE 0
                                    END AS points
                                FROM
                                    (
                                        SELECT
                                            c.userid,
                                            c.product_id,
                                            SUM(price) amt
                                        FROM
                                            (
                                                SELECT
                                                    a.*,
                                                    b.price
                                                FROM
                                                    sales a
                                                    INNER JOIN product b ON a.product_id = b.product_id
                                            ) c
                                        GROUP BY
                                            userid,
                                            product_id
                                    ) d
                            ) e
                    ) f
                GROUP BY
                    product_id
                ORDER BY
                    product_id
            ) f
    ) g
WHERE
    rnk = 1


-- (10) In the first year after a customer joins the Gold program (including their join date), irrespective of what the customer has purchased, they earn 5 Zomato points for every 10 rs spent. Determine whether customer 1 or customer 3 earned more, and what was their points earnings in their first year.
-- 1 zomato point = 2 rs
-- 0.5 zomato point = 1 rs

SELECT
    c.*,
    d.price * 0.5 total_points_earned
FROM
    (
        SELECT
            a.userid,
            a.created_date,
            a.product_id,
            b.gold_signup_date
        FROM
            sales a
            INNER JOIN goldusers_signup b ON a.userid = b.userid
            AND created_date >= gold_signup_date
            AND created_date <= b.gold_signup_date + INTERVAL '1 year'
    ) c
    INNER JOIN product d ON c.product_id = d.product_id


-- (11) Rank all the transactions of the customers.

SELECT
    *,
    RANK() OVER(
        PARTITION BY userid
        ORDER BY
            created_date
    ) rnk
FROM
    sales;


-- (12) Rank all the transactions for each member during their Zomato Gold membership period, and mark every non-Gold member transaction as 'NA'.

SELECT
    e.*,
    CASE
        WHEN rnk = '0' THEN 'na'
        ELSE rnk
    END AS rnkk
FROM
    (
        SELECT
            c.*,
            CASE
                WHEN gold_signup_date IS NULL THEN '0'
                ELSE RANK() OVER(
                    PARTITION BY userid
                    ORDER BY
                        created_date desc
                ):: VARCHAR
            END AS rnk
        FROM
            (
                SELECT
                    a.userid,
                    a.created_date,
                    a.product_id,
                    b.gold_signup_date
                FROM
                    sales a
                    LEFT JOIN goldusers_signup b ON a.userid = b.userid
                    AND created_date >= gold_signup_date
            ) c
    ) e;

    
