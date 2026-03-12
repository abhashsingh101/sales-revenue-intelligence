-- 1. Total revenue by month with MoM growth % using LAG window function
WITH MonthlyRevenue AS (
    SELECT 
        DATEPART(YEAR, OrderDate) AS [Year], 
        DATEPART(MONTH, OrderDate) AS [Month], 
        SUM(TotalAmount) AS TotalRevenue
    FROM Orders
    GROUP BY DATEPART(YEAR, OrderDate), DATEPART(MONTH, OrderDate)
)
SELECT 
    [Year], 
    [Month], 
    TotalRevenue,
    LAG(TotalRevenue) OVER (ORDER BY [Year], [Month]) AS PreviousMonthRevenue,
    ((TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY [Year], [Month])) * 100.0 / LAG(TotalRevenue) OVER (ORDER BY [Year], [Month])) AS MoMGrowthPercentage
FROM MonthlyRevenue;

-- 2. Revenue by region and product category pivot-style analysis with percentage of region revenue
SELECT 
    Region,
    ProductCategory,
    SUM(TotalAmount) AS TotalRevenue,
    SUM(TotalAmount) * 100.0 / SUM(SUM(TotalAmount)) OVER (PARTITION BY Region) AS PercentageOfRegionRevenue
FROM Orders
JOIN Products ON Orders.ProductID = Products.ProductID
GROUP BY Region, ProductCategory
ORDER BY Region, ProductCategory;

-- 3. Top 10 sales representatives by revenue and units sold with RANK window function
WITH SalesRankings AS (
    SELECT 
        SalesRepID, 
        SUM(TotalAmount) AS TotalRevenue, 
        SUM(Quantity) AS TotalUnitsSold,
        RANK() OVER (ORDER BY SUM(TotalAmount) DESC) AS SalesRank
    FROM Sales
    GROUP BY SalesRepID
)
SELECT *
FROM SalesRankings
WHERE SalesRank <= 10;

-- 4. Average discount impact on revenue per category with discount buckets
SELECT 
    ProductCategory,
    CASE 
        WHEN AVG(Discount) < 5 THEN 'Low'
        WHEN AVG(Discount) BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'High'
    END AS DiscountBucket,
    AVG(TotalAmount - Discount) AS AverageRevenueImpact
FROM Orders
JOIN Products ON Orders.ProductID = Products.ProductID
GROUP BY ProductCategory;

-- 5. Return rate analysis by product and region
SELECT 
    Region,
    ProductID,
    COUNT(CASE WHEN IsReturned = 1 THEN 1 END) AS ReturnCount,
    COUNT(*) AS TotalSold,
    COUNT(CASE WHEN IsReturned = 1 THEN 1 END) * 100.0 / COUNT(*) AS ReturnRatePercentage
FROM Orders
GROUP BY Region, ProductID;

-- 6. Customer segment profitability analysis showing revenue minus discounts
SELECT 
    CustomerSegment,
    SUM(TotalAmount - Discount) AS Profitability
FROM Orders
JOIN Customers ON Orders.CustomerID = Customers.CustomerID
GROUP BY CustomerSegment;

-- 7. Delivery time analysis with average days by region and SLA compliance
SELECT 
    Region,
    AVG(DATEDIFF(DAY, OrderDate, DeliveryDate)) AS AverageDeliveryTime,
    SUM(CASE WHEN DATEDIFF(DAY, OrderDate, DeliveryDate) <= SLA THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS SLAPerformancePercentage
FROM Orders
GROUP BY Region;

-- 8. Quarter-over-quarter revenue growth tracking
WITH QuarterlyRevenue AS (
    SELECT 
        DATEPART(YEAR, OrderDate) AS [Year], 
        DATEPART(QUARTER, OrderDate) AS [Quarter], 
        SUM(TotalAmount) AS TotalRevenue
    FROM Orders
    GROUP BY DATEPART(YEAR, OrderDate), DATEPART(QUARTER, OrderDate)
)
SELECT 
    [Year], 
    [Quarter], 
    TotalRevenue,
    LAG(TotalRevenue) OVER (ORDER BY [Year], [Quarter]) AS PreviousQuarterRevenue,
    ((TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY [Year], [Quarter])) * 100.0 / LAG(TotalRevenue) OVER (ORDER BY [Year], [Quarter])) AS QoQGrowthPercentage
FROM QuarterlyRevenue;

-- 9. Running total revenue using window functions with 7-day moving average
SELECT 
    OrderDate,
    SUM(TotalAmount) OVER (ORDER BY OrderDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS RunningTotal,
    AVG(TotalAmount) OVER (ORDER BY OrderDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS SevenDayMovingAverage
FROM Orders;

-- 10. Rank sales reps within each region using RANK() and DENSE_RANK()
SELECT 
    Region,
    SalesRepID,
    TotalRevenue,
    RANK() OVER (PARTITION BY Region ORDER BY TotalRevenue DESC) AS SalesRepRank,
    DENSE_RANK() OVER (PARTITION BY Region ORDER BY TotalRevenue DESC) AS SalesRepDenseRank
FROM (
    SELECT 
        SalesRepID,
        Region,
        SUM(TotalAmount) AS TotalRevenue
    FROM Sales
    JOIN Orders ON Sales.OrderID = Orders.OrderID
    GROUP BY SalesRepID, Region
) AS RegionalSales;

-- 11. Identify underperforming products below average revenue with performance status
WITH AverageRevenue AS (
    SELECT AVG(TotalAmount) AS AverageRevenue
    FROM Orders
)
SELECT 
    ProductID,
    SUM(TotalAmount) AS TotalRevenue,
    CASE 
        WHEN SUM(TotalAmount) < (SELECT AverageRevenue FROM AverageRevenue) THEN 'Underperforming'
        ELSE 'Performing'
    END AS PerformanceStatus
FROM Orders
GROUP BY ProductID;

-- 12. Monthly sales target vs actual with variance analysis
SELECT 
    Month,
    Year,
    SalesTarget,
    ActualSales,
    ActualSales - SalesTarget AS SalesVariance
FROM (
    SELECT 
        DATEPART(MONTH, OrderDate) AS Month,
        DATEPART(YEAR, OrderDate) AS Year,
        SUM(SalesTarget) AS SalesTarget,
        SUM(TotalAmount) AS ActualSales
    FROM SalesTargets
    LEFT JOIN Orders ON DATEPART(MONTH, OrderDate) = SalesTargets.Month
    AND DATEPART(YEAR, OrderDate) = SalesTargets.Year
    GROUP BY DATEPART(MONTH, OrderDate), DATEPART(YEAR, OrderDate)
) AS MonthlyAnalysis;