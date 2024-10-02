const express = require('express');
const { connectToNetwork } = require('../fabric/gateway');

const router = express.Router();

// Add a New Product
const addProduct = async (req, res) => {
    const { productID, name, description, manufacturingDate, batchNumber } = req.body;
    try {
        const { contract, gateway } = await connectToNetwork('channel2', 'supplychain', 'Producer');
        await contract.submitTransaction('CreateProduct', productID, name, description, manufacturingDate, batchNumber);
        res.status(200).send('Product added successfully.');
        await gateway.disconnect();
    } catch (error) {
        res.status(500).send(`Error adding product: ${error.message}`);
    }
};

// Supply a Product
const restockProduct = async (req, res) => {
    const { productID, supplyDate, warehouseLocation } = req.body;
    try {
        const { contract, gateway } = await connectToNetwork('channel2', 'supplychain', 'Supplier');
        await contract.submitTransaction('SupplyProduct', productID, supplyDate, warehouseLocation);
        res.status(200).send('Product restocked successfully.');
        await gateway.disconnect();
    } catch (error) {
        res.status(500).send(`Error restocking product: ${error.message}`);
    }
};

// Handle Wholesale Transactions
const wholesaleProduct = async (req, res) => {
    const { productID, wholesaleDate, wholesaleLocation, quantity } = req.body;
    try {
        const { contract, gateway } = await connectToNetwork('channel3', 'supplychain', 'Wholesaler');
        await contract.submitTransaction('WholesaleProduct', productID, wholesaleDate, wholesaleLocation, quantity);
        res.status(200).send('Product wholesaled successfully.');
        await gateway.disconnect();
    } catch (error) {
        res.status(500).send(`Error wholesaling product: ${error.message}`);
    }
};

// Retrieve Product Information
const getProductDetails = async (req, res) => {
    const { productID } = req.params;
    try {
        const { contract, gateway } = await connectToNetwork('channel1', 'supplychain', 'Producer');
        const result = await contract.evaluateTransaction('QueryProduct', productID);
        res.status(200).json(JSON.parse(result.toString()));
        await gateway.disconnect();
    } catch (error) {
        res.status(500).send(`Error retrieving product: ${error.message}`);
    }
};

// Process a Sale
const processSale = async (req, res) => {
    const { productID, buyerInfo } = req.body;
    try {
        const { contract, gateway } = await connectToNetwork('channel1', 'supplychain', 'Wholesaler');
        await contract.submitTransaction('UpdateProductStatus', productID, 'Sold', buyerInfo);
        res.status(200).send('Product sold successfully.');
        await gateway.disconnect();
    } catch (error) {
        res.status(500).send(`Error selling product: ${error.message}`);
    }
};

// Define routes
router.post('/add', addProduct);
router.post('/restock', restockProduct);
router.post('/wholesale', wholesaleProduct);
router.get('/fetch/:productID', getProductDetails);
router.post('/sell', processSale);

module.exports = router;

