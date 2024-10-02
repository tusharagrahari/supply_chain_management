package contracts

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// AssetManager defines the contract for asset management
type AssetManager struct {
	contractapi.Contract
}

// Asset represents the details of a product asset
type Asset struct {
	ProductID          string `json:"ProductID"`
	Name               string `json:"Name"`
	Description        string `json:"Description"`
	ManufacturingDate  string `json:"ManufacturingDate"`
	BatchNumber        string `json:"BatchNumber"`
	SupplyDate         string `json:"SupplyDate"`
	WarehouseLocation   string `json:"WarehouseLocation"`
	WholesaleDate      string `json:"WholesaleDate"`
	WholesaleLocation   string `json:"WholesaleLocation"`
	WholesaleQuantity   string `json:"WholesaleQuantity"`
	Status             string `json:"Status"`
}

// InitializeAssets populates the ledger with initial assets
func (m *AssetManager) InitializeAssets(ctx contractapi.TransactionContextInterface) error {
	initialAssets := []Asset{
		{ProductID: "asset1", Name: "Samsung", Description: "Samsung", ManufacturingDate: "2024-01-01", BatchNumber: "B1", SupplyDate: "2024-01-02", WarehouseLocation: "W1", WholesaleDate: "2024-01-03", WholesaleLocation: "WL1", WholesaleQuantity: "100", Status: "NA"},
		{ProductID: "asset2", Name: "IQOO", Description: "IQOO", ManufacturingDate: "2028-01-01", BatchNumber: "B1", SupplyDate: "2028-01-02", WarehouseLocation: "W1", WholesaleDate: "2028-01-03", WholesaleLocation: "WL1", WholesaleQuantity: "100", Status: "sold"},
	}

	for _, asset := range initialAssets {
		assetData, err := json.Marshal(asset)
		if err != nil {
			return err
		}

		if err := ctx.GetStub().PutState(asset.ProductID, assetData); err != nil {
			return fmt.Errorf("could not save asset to ledger: %v", err)
		}
	}

	return nil
}

// AddAsset creates a new asset with specified details.
func (m *AssetManager) AddAsset(ctx contractapi.TransactionContextInterface, productID, name, description, manufacturingDate, batchNumber string) error {
	exists, err := m.AssetExists(ctx, productID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("asset %s already exists", productID)
	}

	newAsset := Asset{
		ProductID:         productID,
		Name:              name,
		Description:       description,
		ManufacturingDate: manufacturingDate,
		BatchNumber:       batchNumber,
		SupplyDate:        "NA",
		WarehouseLocation:  "NA",
		WholesaleDate:      "NA",
		WholesaleLocation:  "NA",
		WholesaleQuantity:  "NA",
		Status:            "created",
	}
	assetData, err := json.Marshal(newAsset)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(productID, assetData)
}

// GetAsset retrieves an asset from the ledger by its ID.
func (m *AssetManager) GetAsset(ctx contractapi.TransactionContextInterface, id string) (*Asset, error) {
	assetData, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("error reading asset from ledger: %v", err)
	}
	if assetData == nil {
		return nil, fmt.Errorf("asset %s does not exist", id)
	}

	var asset Asset
	if err := json.Unmarshal(assetData, &asset); err != nil {
		return nil, err
	}

	return &asset, nil
}

// UpdateAsset modifies an existing asset's status.
func (m *AssetManager) UpdateAsset(ctx contractapi.TransactionContextInterface, id, status string) error {
	exists, err := m.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("asset %s does not exist", id)
	}

	asset := Asset{
		ProductID: id,
		Status:    status,
	}
	assetData, err := json.Marshal(asset)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, assetData)
}

// SupplyAsset updates supply details for a given asset.
func (m *AssetManager) SupplyAsset(ctx contractapi.TransactionContextInterface, id, supplyDate, warehouseLocation string) error {
	exists, err := m.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("asset %s does not exist", id)
	}
	asset, err := m.GetAsset(ctx, id)
	if err != nil {
		return err
	}
	asset.SupplyDate = supplyDate
	asset.WarehouseLocation = warehouseLocation
	asset.Status = "Supplied"
	assetData, err := json.Marshal(asset)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, assetData)
}

// WholesaleAsset updates wholesale details for a given asset.
func (m *AssetManager) WholesaleAsset(ctx contractapi.TransactionContextInterface, id, wholesaleDate, wholesaleLocation, wholesaleQuantity string) error {
	exists, err := m.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("asset %s does not exist", id)
	}
	asset, err := m.GetAsset(ctx, id)
	if err != nil {
		return err
	}
	asset.WholesaleDate = wholesaleDate
	asset.WholesaleLocation = wholesaleLocation
	asset.WholesaleQuantity = wholesaleQuantity
	asset.Status = "Wholesaled"
	assetData, err := json.Marshal(asset)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, assetData)
}

// QueryAsset returns the details of an asset.
func (m *AssetManager) QueryAsset(ctx contractapi.TransactionContextInterface, id string) (*Asset, error) {
	return m.GetAsset(ctx, id)
}

// ChangeAssetStatus updates the status of an asset.
func (m *AssetManager) ChangeAssetStatus(ctx contractapi.TransactionContextInterface, id, status string) error {
	exists, err := m.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("asset %s does not exist", id)
	}
	asset, err := m.GetAsset(ctx, id)
	if err != nil {
		return err
	}

	asset.Status = status
	assetData, err := json.Marshal(asset)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, assetData)
}

// RemoveAsset deletes an asset from the ledger.
func (m *AssetManager) RemoveAsset(ctx contractapi.TransactionContextInterface, id string) error {
	exists, err := m.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("asset %s does not exist", id)
	}

	return ctx.GetStub().DelState(id)
}

// AssetExists checks if an asset exists in the ledger.
func (m *AssetManager) AssetExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	assetData, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to check asset existence: %v", err)
	}

	return assetData != nil, nil
}

// RetrieveAllAssets fetches all assets from the ledger.
func (m *AssetManager) RetrieveAllAssets(ctx contractapi.TransactionContextInterface) ([]*Asset, error) {
	iterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer iterator.Close()

	var assets []*Asset
	for iterator.HasNext() {
		response, err := iterator.Next()
		if err != nil {
			return nil, err
		}

		var asset Asset
		if err := json.Unmarshal(response.Value, &asset); err != nil {
			return nil, err
		}
		assets = append(assets, &asset)
	}

	return assets, nil
}
