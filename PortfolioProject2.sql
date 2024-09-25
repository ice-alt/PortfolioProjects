create database PortfolioProject2;
use PortfolioProject2;

-- Cleaning Data in SQL Queries
SELECT *
FROM portfolioproject2.nashville_housing;

-- Standardize date format (remove the 00:00:00)

-- This didn't work
UPDATE portfolioproject2.nashville_housing
SET SaleDate = CONVERT(SaleDate, Date);

-- So try this method
ALTER TABLE portfolioproject2.nashville_housing
Add SaleDateConverted Date;

UPDATE portfolioproject2.nashville_housing
SET SaleDateConverted = CONVERT(SaleDate, Date);

SELECT SaleDateConverted
FROM portfolioproject2.nashville_housing;


-- Populate Property Address Data (the 'Null' values here are just blank spaces)

SELECT *
FROM portfolioproject2.nashville_housing
WHERE PropertyAddress = '';

SELECT *
FROM portfolioproject2.nashville_housing
ORDER BY ParcelID;

-- JOIN the data upon itself to find the reference for the missing values
-- The UniqueID should not match since 1. It's meant to be Unique and 2. if it's avoiding
-- duplicates, we can see what the missing values could be property addresses with the same
-- parcelID
SELECT nashA.ParcelID, nashA.PropertyAddress, nashB.ParcelID, nashB.PropertyAddress
FROM portfolioproject2.nashville_housing nashA
JOIN portfolioproject2.nashville_housing nashB
	ON nashA.ParcelID = nashB.ParcelID
    AND nashA.UniqueID <> nashB.UniqueID
WHERE nashA.PropertyAddress = '';

-- For NULL values, the command ISNULL(nashA.PropertyAddress, nashB.PropertyAddress) would
-- have been used to populate the NULL data in nashA.PropertyAddress with
-- nashB.PropertyAddress. But since these are blank values, we'll use IF
SELECT nashA.ParcelID, nashA.PropertyAddress, nashB.ParcelID, nashB.PropertyAddress,
IF(nashA.PropertyAddress = '', nashB.PropertyAddress, nashA.PropertyAddress)
FROM portfolioproject2.nashville_housing nashA
JOIN portfolioproject2.nashville_housing nashB
	ON nashA.ParcelID = nashB.ParcelID
    AND nashA.UniqueID <> nashB.UniqueID
WHERE nashA.PropertyAddress = '';

-- To clarify, the IF command states that if nashA.PropertyAddress is blank then replace
-- it with nashB.PropertyAddress or leave it as is (nashA.PropertyAddress)
UPDATE portfolioproject2.nashville_housing nashA
JOIN portfolioproject2.nashville_housing nashB
    ON nashA.ParcelID = nashB.ParcelID
    AND nashA.UniqueID <> nashB.UniqueID
SET nashA.PropertyAddress = IF(nashA.PropertyAddress = '', nashB.PropertyAddress, nashA.PropertyAddress)
WHERE nashA.PropertyAddress = '';


-- Breaking out Address into Individual Columns (Address, City, State)
SELECT PropertyAddress
FROM portfolioproject2.nashville_housing;

-- LOCATE returns the index of the charcter in the first paramter from the seconf String parameter
-- Note that -1 was used in the first statement to avoid including the comma (,) when printing
-- out the Address. In the same vein, +1 was used in the second statement to avoid the comma
-- and go to the next character
SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS Address
FROM portfolioproject2.nashville_housing;

ALTER TABLE portfolioproject2.nashville_housing
Add PropertySplitAddress nvarchar(255);

UPDATE portfolioproject2.nashville_housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1);

ALTER TABLE portfolioproject2.nashville_housing
Add PropertySplitCity nvarchar(255);

UPDATE portfolioproject2.nashville_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));

SELECT *
FROM portfolioproject2.nashville_housing;



SELECT OwnerAddress
FROM portfolioproject2.nashville_housing;

-- SUBSTRING_INDEX returns everything to the left of the delimiter. up to the number of occurrences
 -- Therefore, when you use you specify it, you may still have to remove some parts of the 
-- substring that are not wanted before the delimiter

-- SUBSTRING_INDEX(OwnerAddress, ',', 1) gives the part before the first comma
-- SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) extracts the second part by 
-- first taking the substring up to the second comma and then extracting the last portion 
-- after the first comma
-- SUBSTRING_INDEX(OwnerAddress, ',', -1) gives the last part 
SELECT
SUBSTRING_INDEX(OwnerAddress, ',', 1),-- (Address)
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),-- (City)
SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State -- (State)
FROM portfolioproject2.nashville_housing;


ALTER TABLE portfolioproject2.nashville_housing
Add OwnerSplitAddress nvarchar(255);

UPDATE portfolioproject2.nashville_housing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE portfolioproject2.nashville_housing
Add OwnerSplitCity nvarchar(255);

UPDATE portfolioproject2.nashville_housing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE portfolioproject2.nashville_housing
Add OwnerSplitState nvarchar(255);

UPDATE portfolioproject2.nashville_housing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT *
FROM portfolioproject2.nashville_housing;



-- Change Y and N to Yes and No In "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant)
FROM portfolioproject2.nashville_housing;

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM portfolioproject2.nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM portfolioproject2.nashville_housing;


UPDATE portfolioproject2.nashville_housing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END;


-- Remove Duplicates (Here we will actually delete values but it may not be needed in all
-- situations, depending on the data you are working with)

-- We are assuming that rows that have the same ParcelID, PropoertAddress, SalePrice, SaleDate,
-- and LegalReference are duplicates of each other (ignoring the UniqueID)
-- Note: Duplicates of each other, for instance a single repitition, would have row_num as 1 for
-- the first original data and 2 for the duplicated data (it can be up to 3, 4 etc according)
-- to how many duplicates there are
SELECT *,
ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID) row_num
FROM portfolioproject2.nashville_housing
ORDER BY ParcelID;

-- Now let's get the duplicates, that is, where row_num > 1. We will use a CTE to cover our
-- previous expression
WITH RowNumCTE AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID) row_num
FROM portfolioproject2.nashville_housing)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- And now delete them (for MySQL workbench, you cannot directly delete from CTEs)
-- However, you can use the CTE to identify which rows need to be deleted then you can use
-- another query to delete them from the actual table. 

DELETE FROM portfolioproject2.nashville_housing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID,
               ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID) AS row_num
        FROM portfolioproject2.nashville_housing
    ) AS duplicates -- you need to wrap it in an alias for it to work
    WHERE row_num > 1);


-- Delete Unused columns 
SELECT *
FROM portfolioproject2.nashville_housing;

ALTER TABLE portfolioproject2.nashville_housing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;

ALTER TABLE portfolioproject2.nashville_housing
DROP COLUMN SaleDate;





