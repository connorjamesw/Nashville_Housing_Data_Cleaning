-- DATA CLEANING IN SQL USING NASHVILLE HOUSING DATA


-- DATASOURCE: https://www.kaggle.com/tmthyjames/nashville-housing-data



--####################################################################################
-- Standardising Date Format


-- SaleDate is given in a DATETIME format, with hours, mins, seconds included.
-- DATE format, giving just the day, month and year, is the desired foramt


-- Adding new date column which lists the date in DATE form

ALTER TABLE NashvilleHousing
ADD SalesDateConverted DATE;

UPDATE NashvilleHousing
SET SalesDateConverted = CONVERT(DATE,SaleDate);



--####################################################################################
-- Populate Property Address data


-- Some of the property addresses in the data set are NULL.

-- ParcelIDs corrospond to property address. So, if for one record a ParcelID and a property address are listed, and for another record 
-- the same ParcelID but a NULL property address, we will populate the NULL property address with the address corrosponding to the given ParcelID.


-- The following query returns records from the NashvilleHousing table for which PropertyAddress is NULL and the ParcelID is not unique to that record.
-- It additionally returns the PropertyAddress of a different but corrosponding record with the same ParcelID.

SELECT a.ParcelID, a.PropertyAddress, b.PropertyAddress
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID 
	AND a.UniqueID <> b.UniqueID  
WHERE a.PropertyAddress IS NULL ;

-- For all such records I will populate the NULL PropertyAddress with the PropertyAddress of the record with the corrosponding ParcelID. Done so using 'ISNULL'

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID 
	AND a.UniqueID <> b.UniqueID  
WHERE a.PropertyAddress IS NULL ;









--####################################################################################
-- Breaking out PropertyAddress into Individual Columns (Address, City)

-- As is stands, PropertyAddress is given as 'adddress number, city' with street name and city separated by a comma.


-- Creating separate columns for Address and City from the PropertyAddress column.


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1 ,CHARINDEX(',',PropertyAddress) -1 );


ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1 ,LEN(PropertyAddress));






--####################################################################################
-- Breaking out OwnerAddress into separate columns. 

-- OwnerAddress is given as 'address, city, state' with address, city and state separated by commas.


-- USING PARSENAME to split OwnerAddress into there separate columns. The following query will return a three column output, one for address, city and state.
-- PARSENAME looks for fullstops not commas,  so we need to replace all commas with fullstops in the OwnerAddress first before applying PARSENAME.

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM NashvilleHousing;


-- Creating new columns for address, city and state from the OwnerAddress column

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)




ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)



ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)




--####################################################################################

-- Changing Y and N to Yes and No in "Sold as Vacant" field

-- Most columns are populated with 'Yes' or 'No' already

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant;

 
-- Replacing examples of Y and N in the SoldAsVacant column with 'Yes' and 'No' using a CASE statement


UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END;






--####################################################################################

-- Identifying Duplicates



-- Partioning by ROW_NUMBER() over five different fields


SELECT *, 
	ROW_NUMBER() OVER (     -- NB: ROW_NUMBER() returns the sequential number of a row within a partition of a result set
	PARTITION BY ParcelID,
		         PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) AS row_num
FROM NashvilleHousing


-- Records should be unqiue across these fields - if a record is the same as another across all five fields then it is likely to be a duplicate record.
-- Row numbers will be assigned within each partition, starting with 1, 2, etc.
-- Unique rows should exist in their own partition with a row_num of 1.
-- Any partition that includes more than one row number will include example(s) of duplicate records.




-- Using a common table expression to query off of the above, selecting only records with an assigned row_num greater than 1.
-- This will return an output of all the duplicate records.


WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (     
	PARTITION BY ParcelID,
		         PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) AS row_num

FROM NashvilleHousing
)
SELECT * FROM RowNumCTE
WHERE row_num > 1  
ORDER BY PropertyAddress;




-- The following query will remove these records identified as duplicates from the table.
-- I have opted to not delete these records.

--WITH RowNumCTE AS(
--SELECT *, 
--	ROW_NUMBER() OVER (
--	PARTITION BY ParcelID,
--		         PropertyAddress,
--				 SalePrice,
--				 SaleDate,
--				 LegalReference
--				 ORDER BY UniqueID
--				 ) AS row_num

--FROM NashvilleHousing
--)
--DELETE 
--FROM RowNumCTE
--WHERE row_num > 1;







--####################################################################################

-- Deleting columns made redundant by the newly created ones.

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress;




