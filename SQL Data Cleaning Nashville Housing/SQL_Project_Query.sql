/*

Data Cleaning In SQL From Nashville Housing Data 

*/


SELECT * 
FROM PortfolioProjects.dbo.NashvilleHousing



-- Standardize Date Format

SELECT SaleDateConverted, CONVERT(Date, SaleDate) 
FROM PortfolioProjects.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)



-- Populate Property Address Data

SELECT TOP 100 a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHousing a
JOIN PortfolioProjects.dbo.NashvilleHousing b
 ON a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress  IS NULL



UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHousing a
JOIN PortfolioProjects.dbo.NashvilleHousing b
 ON a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress  IS NULL



-- Breaking out address into individual columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioProjects.dbo.NashvilleHousing


SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM PortfolioProjects.dbo.NashvilleHousing



ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
ADD PropertySplitAddress NVarchar(255);

UPDATE PortfolioProjects.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
ADD PropertySplitCity NVarchar(255);

UPDATE PortfolioProjects.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))



SELECT OwnerAddress
FROM PortfolioProjects.dbo.NashvilleHousing


SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProjects.dbo.NashvilleHousing



ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
ADD OwnerSplitAddress NVarchar(255);

UPDATE PortfolioProjects.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
ADD OwnerSplitCity NVarchar(255);

UPDATE PortfolioProjects.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
ADD OwnerSplitState NVarchar(255);

UPDATE PortfolioProjects.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



-- Change Y and N to yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProjects.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2



SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProjects.dbo.NashvilleHousing


UPDATE PortfolioProjects.dbo.NashvilleHousing
SET SoldAsVacant = CASE 
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END



-- Remove Duplicates

WITH RouwNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, 
				 PropertyAddress, 
				 SaleDate, 
				 SalePrice, 
				 LegalReference
				 ORDER BY 
				 UniqueID
				  ) row_num
FROM PortfolioProjects.dbo.NashvilleHousing

	)
SELECT *
FROM RouwNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress



-- Delete unused columns

SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing

ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict