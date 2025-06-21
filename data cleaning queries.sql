SELECT * FROM sql_profolio_project.nashvillehousing;

---------------------------------------------------------------------------- 


-- Standardize Date Format

ALTER TABLE sql_profolio_project.nashvillehousing 
MODIFY COLUMN SaleDate DATE;
-- Change Column SaleDate's datatype from DATETIME to DATE





---------------------------------------------------------------------------- 



-- Populate Property Address Data



SELECT *
FROM  sql_profolio_project.nashvillehousing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID;
-- discovery: Records with the same ParcelID have the same PropertyAddress

SELECT 
	a.ParcelID, 
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    IFNULL(a.PropertyAddress,b.PropertyAddress)
    -- IFNULL returns a specified value if the expression is NULL
FROM sql_profolio_project.nashvillehousing a
JOIN sql_profolio_project.nashvillehousing b
	ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- CREATE TABLE nashvillehousing_backup AS
-- SELECT * FROM sql_profolio_project.nashvillehousing;

-- purpose: create table backup in case the following code doesn't work as intended


UPDATE sql_profolio_project.nashvillehousing a
JOIN sql_profolio_project.nashvillehousing b
	ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress,b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;





---------------------------------------------------------------------------- 



-- Breaking out Address into Individual Columns (Address,City,State)

SELECT PropertyAddress
FROM sql_profolio_project.nashvillehousing;

SELECT 
PropertyAddress,
SUBSTRING(PropertyAddress,1,INSTR(PropertyAddress,',')-1) AS address,
SUBSTRING(PropertyAddress,INSTR(PropertyAddress,',')+1, LENGTH(PropertyAddress)) AS city
FROM sql_profolio_project.nashvillehousing;


ALTER TABLE nashvillehousing
ADD PropertySplitAddress VARCHAR(255);

UPDATE nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,INSTR(PropertyAddress,',')-1);

ALTER TABLE nashvillehousing
ADD PropertySplitCity VARCHAR(255);

UPDATE nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,INSTR(PropertyAddress,',')+1, LENGTH(PropertyAddress));





SELECT OwnerAddress
FROM sql_profolio_project.nashvillehousing;

SELECT
OwnerAddress,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-3),',',1) AS address,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-2),',',1) AS city,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-1),',',1) AS state
FROM sql_profolio_project.nashvillehousing;


ALTER TABLE nashvillehousing
ADD OwnerSplitAddress VARCHAR(255);

UPDATE nashvillehousing
SET OwnerSplitAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-3),',',1);

ALTER TABLE nashvillehousing
ADD OwnerSplitCity VARCHAR(255);

UPDATE nashvillehousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-2),',',1);

ALTER TABLE nashvillehousing
ADD OwnerSplitState VARCHAR(255);

UPDATE nashvillehousing
SET OwnerSplitState = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-1),',',1);


----------------------------------------------------------------------------


-- Change Y and N to Yes and No in "SoldAsVacant" Column


SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant)
FROM sql_profolio_project.nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;
-- purpose: to check how many Y,N,Yes,No there are

SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END AS correct_format
FROM sql_profolio_project.nashvillehousing;
    
UPDATE sql_profolio_project.nashvillehousing
SET SoldAsVacant = 
(CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END);




----------------------------------------------------------------------------


-- Remove Duplicates
-- Only for demonstration, NOT best practice

WITH cte_rownum AS(
SELECT *,
	ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY 
					UniqueID) row_num
FROM sql_profolio_project.nashvillehousing
)
-- SELECT *
DELETE
FROM cte_rownum
WHERE row_num > 1;
				
		
        
        
        
----------------------------------------------------------------------------


-- Delete Unused Columns
-- Only for demonstration, NOT best practice


ALTER TABLE sql_profolio_project.nashvillehousing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress
;
