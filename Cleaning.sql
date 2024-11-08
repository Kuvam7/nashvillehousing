Select *
from nashville..data
ORDER BY SaleDate;

-- Tasks

-- Standardize Date Format

ALTER TABLE nashville..data
ALTER COLUMN SaleDate DATE;

-- Populate Property Address data

SELECT *
FROM nashville..data
where PropertyAddress is null;

-- In this table, the ParcelID column has duplicate values where for one of the duplicates
-- the PropertyAddress is Null, however the address of a house cannot change i.e.
-- you cannot move a house from one location to another after it's built, so we'll use the ParcelID column
-- to populate the PropertyAddress column.

-- we join the table to itself on the parcelID column and we view the ParcelID and PropertyAddress columns
-- we also have a where clause to see for which ParcelID we don't have the address and for the same ParcelID,
-- we have the address in some other row.
-- Now using this query, we have the missing addresses but we still need to impute it in the table using an UPDATE statement

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM nashville..data a
JOIN nashville..data b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null;

-- Here, we have the update statement where we set the column PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
-- What ISNULL does is, it imputes the value after the "," if the value before the "," is null

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM nashville..data a
JOIN nashville..data b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null;


-- Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress
from nashville..data;

-- To do this, all we need to do is separate these 2 strings using ',' as a delimiter. 
-- We use SUBSTRING and PARSENAME

Select 
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress,1) - 1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress,1) + 1, LEN(PropertyAddress)) as City
from nashville..data;

-- Here, we've understood the logic for separting the propertyaddress column into address and city
-- However, this is only if we Query the table this way, we need to actually modify the table now
-- We need to first create 2 new columns, PropAddress and PropCity, then SET them = the above queries

-- Creating the columns
ALTER TABLE nashville..data
ADD PropAddress VARCHAR(255);
ALTER TABLE nashville..data
ADD PropCity VARCHAR(255);

-- Populating the columns
UPDATE nashville..data
SET PropAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress,1) - 1);

UPDATE nashville..data
SET PropCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress,1) + 1, LEN(PropertyAddress));

-- Moving on to OwnerAddress Column, Now, we'll use the PARSENAME function

SELECT
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',','.'),3) as OwnersplitAddress, -- PARSENAME only uses . as delimiter so we replace ',' with '.'
	PARSENAME(REPLACE(OwnerAddress, ',','.'),2) as OwnerCity,
	PARSENAME(REPLACE(OwnerAddress, ',','.'),1) as OwnerState
FROM nashville..data;

-- Alter table commands
ALTER TABLE nashville..data
ADD OwnersplitAddress VARCHAR(255);

ALTER TABLE nashville..data
ADD OwnerCity VARCHAR(255);

ALTER TABLE nashville..data
ADD OwnerState VARCHAR(255);

UPDATE nashville..data
SET OwnersplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3);

UPDATE nashville..data
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2);

UPDATE nashville..data
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1);


-- Removing double spaces from the PropAddress and Ownersplitaddress Column
UPDATE nashville..data
SET PropAddress = REPLACE(PropAddress, '  ',' ');
UPDATE nashville..data
SET OwnerSplitAddress = REPLACE(OwnersplitAddress, '  ',' ');

-- Homes where the owner's address is different from the property address i.e. owner doesn't live at the property
SELECT *
FROM nashville..data
where propaddress <> ownersplitaddress;

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT SoldAsVacant
FROM nashville..data
Where SoldAsVacant = 'Y';

UPDATE nashville..data
SET SoldAsVacant = REPLACE(SoldAsVacant,'Y','Yes')
UPDATE nashville..data
SET SoldAsVacant = REPLACE(SoldAsVacant,'N','No')



-- Remove Duplicates using Window function - ROW_NUMBER()
WITH no_dup AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID
	) as rownum
FROM nashville..data
)
Select *
From row_num
Where rownum = 1;


-- Delete Unused Columns

ALTER TABLE nashville..data
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict;
