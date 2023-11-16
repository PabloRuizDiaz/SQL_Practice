-- ####################################################
-- ################# Excercise 1 ######################
-- ####################################################

-- 1) All data of the customers in Las Vegas.
SELECT * FROM customers c WHERE city = 'Las Vegas';

-- 2) All data of the customers not in Las Vegas.
SELECT * FROM customers c WHERE NOT city = 'Las Vegas';

-- 3) Name, phone, and address data of the customers who have a credit limit greater than 10,000.
SELECT 
	customerName AS name
	, phone 
	, addressLine1 AS address
FROM customers c 
WHERE creditLimit > 10000;

-- 4) Order number and Order Date of all the on-hold orders. 
SELECT 
	orderNumber 
	, orderDate 
FROM orders o 
WHERE status = 'On Hold';

-- 5) Name and phone of the customers neither in Las Vegas nor Melbourne.
SELECT 
	customerName AS customerName 
	, phone 
FROM customers c 
WHERE NOT city IN ('Las Vegas', 'Melbourne');

-- 6) All data of the orders that were placed before 2005.
SELECT * FROM orders o WHERE YEAR(requiredDate) < 2005;

-- 7) All the data of the orders that were placed in 2004. 
SELECT * FROM orders o WHERE YEAR(requiredDate) = 2004;

-- 8) Order number, shipped date, and comments of the orders that were shipped in 2005.
SELECT 
	orderNumber 
	, shippedDate 
	, comments 
FROM orders o 
WHERE YEAR(shippedDate) = 2005;

-- 9) Order number, shipped date, and comments of the orders that were placed in 2004 and 2005 and had any comment.
SELECT 
	orderNumber 
	, shippedDate 
	, comments 
FROM orders o 
WHERE (YEAR(shippedDate) BETWEEN 2004 AND 2005) AND NOT ISNULL(comments);

-- 10) All the data of the orders that were not shipped, not ordered in 2003, and with a comment. 
SELECT * FROM orders o 
WHERE
	ISNULL(shippedDate)
	AND YEAR(orderDate) != 2003
	AND NOT ISNULL(comments);
	
-- 11) All data of the employees who report to VP Sales.
SELECT * FROM employees e WHERE reportsTo = (
	SELECT employeeNumber FROM employees e2 WHERE jobTitle = 'VP Sales'
);

-- ####################################################
-- ################# Excercise 2 ######################
-- ####################################################

-- 1) Full name of the employees who work for the offices 1, 4 and 5.
SELECT 
	CONCAT(firstName, ' ', lastName) AS fullName 
FROM employees e
WHERE officeCode IN (1,4,5);

-- 2) All data of the customers who the second highest and third highest credit limit. 
SELECT * FROM customers c ORDER BY creditLimit DESC LIMIT 1,2;

-- 3) All data of the customers whose name starts with ‘a’.
SELECT * FROM customers c WHERE customerName LIKE 'a%';

-- 4) Order Numbers of order that had at least one item with a total cost greater than $ 200.
SELECT DISTINCT orderNumber FROM orderdetails o WHERE priceEach > 200;

-- 5) All data of the employees whose last name starts with ‘p’ and who work for the office 1.
SELECT * FROM employees e WHERE (lastName LIKE 'p%') AND (officeCode = 1);

-- 6) All data of the employees with E and S in any part of their name.
SELECT * FROM employees e 
WHERE 
	CONCAT(firstName,lastName) LIKE '%e%' 
	AND CONCAT(firstName,lastName) LIKE '%s%';
	
-- 7) Order Number, Order Line Number, Product Code, and Total Cost of Order Items with a unit cost between 50 and 100 
-- and a total cost that is less than 1000, sorted by Order Number, and Order Line Number (both in ascending order). 
SELECT 
	orderNumber 
	, orderLineNumber 
	, productCode 
	, SUM(priceEach * quantityOrdered) AS totalCost
FROM orderdetails o 
WHERE priceEach BETWEEN 50 AND 100
GROUP BY orderNumber, orderLineNumber, productCode
HAVING totalCost < 1000
ORDER BY orderNumber ASC, orderLineNumber ASC;

-- 8) Name and phone of the customers who are in France, USA, Australia, or Norway whose Address Line 2 is Not Null.
SELECT 
	customerName
	, phone 
FROM customers c 
WHERE 
	country IN ('France', 'USA', 'Australia', 'Norway')
	AND NOT ISNULL(addressLine2);
	
-- ####################################################
-- ################# Excercise 3 ######################
-- ####################################################

-- 1) Product name, product code, product line, and product line description of all the products.
SELECT 
	p.productName 
	, p.productCode 
	, p.productLine 
	, p2.textDescription AS productLineDescription
FROM products p 
INNER JOIN productlines p2 
	USING(productLine);
	
-- 2) Order number, order date, required date, order status, line item number, quantity, unit cost, and total cost of each line item of orders that were placed in 2005. 
SELECT 
	o.orderNumber 
	, o.orderDate 
	, o.requiredDate 
	, o.status 
	, od.orderLineNumber 
	, od.quantityOrdered 
	, od.priceEach AS unitCost
	, SUM(od.priceEach * od.quantityOrdered) AS totalCostByLineNumber
FROM orders o 
INNER JOIN orderdetails od 
	USING(orderNumber)
WHERE YEAR(o.orderDate) = 2005
GROUP BY 
	o.orderNumber 
	, o.orderDate 
	, o.requiredDate 
	, o.status 
	, od.orderLineNumber 
	, od.quantityOrdered 
	, od.priceEach;
	
-- 3) Product names (list separated by ‘|’), and product count of each product line, product line, and product line description of all the products lines.
SELECT 
	p2.productLine 
	, p.textDescription AS productLineDescription
	, GROUP_CONCAT(DISTINCT p2.productName SEPARATOR ' | ') AS productName
	, COUNT(p2.productName) AS productCount
FROM productlines p 
INNER JOIN products p2 
	USING(productLine)
GROUP BY p2.productLine;

-- 4) Employee full name, employee number, total customer count, and total revenue generated (based on sales amounts) of All the employees in USA offices.
SELECT 
	CONCAT(e.lastName, ', ', e.firstName) AS fullNameEmployee
	, e.employeeNumber
	, COUNT(c.customerNumber) AS customerCount
	, SUM(o3.quantityOrdered * o3.priceEach) AS totalRevenue 
FROM employees e 
INNER JOIN customers c 
	ON e.employeeNumber = c.salesRepEmployeeNumber
INNER JOIN offices o 
	USING(officeCode)
INNER JOIN orders o2 
	USING(customerNumber)
INNER JOIN orderdetails o3 
	USING(orderNumber)
WHERE o.country  = 'USA'
GROUP BY e.employeeNumber;

-- 5) Employee full name, employee number, and list of products sold in 2004 by each employee in NYC.
SELECT 
	CONCAT(e.lastName, ', ', e.firstName) AS fullNameEmployee
	, e.employeeNumber
	, GROUP_CONCAT(DISTINCT p.productName SEPARATOR ' | ') AS productList
FROM employees e 
INNER JOIN offices o 
	USING(officeCode)
INNER JOIN customers c 
	ON e.employeeNumber = c.salesRepEmployeeNumber
INNER JOIN orders o2 
	USING(customerNumber)
INNER JOIN orderdetails o3 
	USING(orderNumber)
INNER JOIN products p 
	USING(productCode)
WHERE 
	YEAR(o2.orderDate) = 2004
	AND o.city = 'NYC' 
GROUP BY e.employeeNumber;

-- ####################################################
-- ################# Excercise 4 ######################
-- ####################################################

-- 1) Extract productCode, productName, productDescription, buyPrice, quantityInStock, product name of 
-- max buyPrice and its max buyPrice of each category for all the products.
SELECT
	p.productCode 
	, p.productName 
	, p.productDescription 
	, p.buyPrice 
	, p.quantityInStock 
	, maxProduct.productName AS maxProductName
	, maxProduct.buyPrice AS maxProductPrice
FROM products p 
INNER JOIN (
	SELECT 
		productName
		, productLine 
		, buyPrice 
	FROM products p2
	WHERE buyPrice IN (
		SELECT max(buyPrice) AS maxBuyPrice 
		FROM products p
		GROUP BY productLine
		ORDER BY productLine)) AS maxProduct
	USING(productLine);

-- 2) Extract customerNumber, customerName, phone, creditLimit, orderNumber, total order value, average 
-- order value for customer for all the orders.
SELECT 
	c.customerNumber 
	, c.customerName 
	, c.phone 
	, c.creditLimit
	, o.orderNumber
	, t1.totalOrder
	, t1.avgOrder
FROM customers c 
LEFT JOIN orders o 
	USING(customerNumber)
LEFT JOIN (
	SELECT
		o.orderNumber 
		, SUM(o.priceEach * o.quantityOrdered) AS totalOrder
		, ROUND(AVG(o.priceEach * o.quantityOrdered), 2) AS avgOrder
	FROM orderdetails o 
	INNER JOIN orders o2 
		USING(orderNumber)
	LEFT JOIN customers c 
		USING(customerNumber)
	GROUP BY o.orderNumber) AS t1
	USING(orderNumber);

-- 3) Extract employee number, employee full name, customer count per employee, total customers of the office, 
-- and employee customer percentage (calculated as customer count per employee / customers of the office) of all the employees.
-- Then create a new variable to assign five categories regarding quality as sellers, and then sorting them from best to worst.
SELECT 
	e.employeeNumber 
	, CONCAT(e.lastName, ', ', e.firstName) AS fullName
	, e.officeCode 
	, COUNT(c.customerNumber) AS customerCount
	, t1.customerCountPerOffice
	, ROUND(100 * COUNT(c.customerNumber) / t1.customerCountPerOffice, 2) AS employeeCustomerPercentage
	, CASE 
		WHEN ROUND(100 * COUNT(c.customerNumber) / t1.customerCountPerOffice, 2) >= 90 THEN '5 stars'
		WHEN ROUND(100 * COUNT(c.customerNumber) / t1.customerCountPerOffice, 2) >= 75 THEN '4 stars'
		WHEN ROUND(100 * COUNT(c.customerNumber) / t1.customerCountPerOffice, 2) >= 50 THEN '3 stars'
		WHEN ROUND(100 * COUNT(c.customerNumber) / t1.customerCountPerOffice, 2) >= 40 THEN '2 stars'
		ELSE '1 star'
	END AS sellerQuality
FROM employees e 
LEFT JOIN offices o2 
	USING(officeCode)
LEFT JOIN customers c 
	ON e.employeeNumber = c.salesRepEmployeeNumber 
LEFT JOIN (
	SELECT 
		o.officeCode 
		, COUNT(c.customerNumber) AS customerCountPerOffice
	FROM offices o 
	LEFT JOIN employees e 
		USING(officeCode)
	LEFT JOIN customers c 
		ON e.employeeNumber = c.salesRepEmployeeNumber 
	GROUP BY o.officeCode) AS t1
	USING(officeCode)
GROUP BY e.employeeNumber, e.officeCode , t1.customerCountPerOffice
ORDER BY sellerQuality DESC, employeeCustomerPercentage DESC;