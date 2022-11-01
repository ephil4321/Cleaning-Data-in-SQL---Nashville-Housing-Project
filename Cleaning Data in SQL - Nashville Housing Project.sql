/* 

Cleaning Data in SQL Queries

*/

SELECT *
  FROM [Nashville Housing Project].[dbo].[NashvilleHousing];

-- Standardize Sale Date

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
  FROM [Nashville Housing Project].[dbo].[NashvilleHousing];

ALTER TABLE NashvilleHousing
  ADD SaleDateConverted Date;

UPDATE NashvilleHousing
   SET SaleDateConverted = CONVERT(Date,SaleDate);


-- Populate Property Address Data: For duplicate Parcel IDs, the address is only filled in on one of the lines, leaving rows with null addresses

SELECT *
  FROM [Nashville Housing Project].[dbo].[NashvilleHousing]
 ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
  FROM [Nashville Housing Project].[dbo].[NashvilleHousing] a
  JOIN [Nashville Housing Project].[dbo].[NashvilleHousing] b
     ON a.ParcelID = b.ParcelID
	 AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
 SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Nashville Housing Project].[dbo].[NashvilleHousing] a
JOIN [Nashville Housing Project].[dbo].[NashvilleHousing] b
     ON a.ParcelID = b.ParcelID
	 AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Breaking Address into Individual Columns (Address, City, State)

	-- PropertyAddress with Substrings

SELECT PropertyAddress
FROM [Nashville Housing Project].[dbo].[NashvilleHousing]

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Street_Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS City
  FROM [Nashville Housing Project].[dbo].[NashvilleHousing]

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

	-- Owner Address with PARSENAME

SELECT OwnerAddress
  FROM [Nashville Housing Project].[dbo].[NashvilleHousing]

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
  FROM [Nashville Housing Project].[dbo].[NashvilleHousing]

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM [Nashville Housing Project].[dbo].[NashvilleHousing]
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
  CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ElSE SoldAsVacant
	   END
FROM [Nashville Housing Project].[dbo].[NashvilleHousing]

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ElSE SoldAsVacant
	   END

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
  FROM [Nashville Housing Project].[dbo].[NashvilleHousing]
)
DELETE
  FROM RowNumCTE
 WHERE row_num > 1;

-- Delete unused columns

ALTER TABLE [Nashville Housing Project].[dbo].[NashvilleHousing]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
