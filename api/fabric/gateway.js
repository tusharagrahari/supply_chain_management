const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

const connectToNetwork = async (channelName, contractName, orgName) => {
    try {
        // Load network connection configuration
        const ccpPath = path.resolve(__dirname, '..', 'connection', `connection-${orgName}.json`);
        const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

        // Create a wallet for managing identities
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        // Check to see if the identity exists in the wallet
        const identity = await wallet.get(orgName);
        if (!identity) {
            console.log(`An identity for the organization "${orgName}" does not exist in the wallet`);
            return;
        }

        // Create a new gateway for connecting to the peer node
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: orgName, discovery: { enabled: true, asLocalhost: true } });

        // Get the network (channel) our contract is deployed to
        const network = await gateway.getNetwork(channelName);

        // Get the contract from the network
        const contract = network.getContract(contractName);

        return { contract, gateway };
    } catch (error) {
        console.error(`Failed to connect to network: ${error}`);
        process.exit(1);
    }
};

module.exports = { connectToNetwork };
