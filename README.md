# Chainlink: Invoice Interest Rate Oracle

This POC creates an External Adapter that returns appropriate LTV interest rates, based on an invoice credit risk score received as parameter, and a Consumer smart contract which will request the rate on demand.

**Note:** The following steps require some basic knowledge about the Chainlink stack: how to run a Chainlink Node, create Jobs, Bridges and External Initiators in the node, and deploy External Adapter functions. It is advisable to start by reading the [Chainlink Docs](https://docs.chain.link).

### Steps for running this POC

#### 1. Run a Chainlink node

  Reference docs: https://docs.chain.link/docs/running-a-chainlink-node

  - Within the `.chainlink-kovan` directory create a `.env` file, copy content of `.env.example` and update `ETH_URL` with your Infura PROJECT_ID

  - Run:
  ```bash
  $ docker run -p 6688:6688 -v PROJECT_PATH:/chainlink -it --env-file=.env smartcontract/chainlink local n
  ```
  (where `PROJECT_PATH` is the path to the root of this directory).

  The first time running the docker image, you will be asked for a password and confirmation. This will be your wallet password, used for unlocking the generated keystore file. Then, you will be prompted to enter an API email and password.

  The Chainlink node can be supplied with files for the wallet password and API email and password (on separate lines) on startup so that you don't need to enter credentials when starting the node. You can create an API file by running the following:

  ```bash
  echo "user@example.com" > .api
  echo "password" >> .api
  echo "my_wallet_password" > .password
  ```

  From now on, you can startup the node running the following command within the `.chainlink-kovan` directory:

  ```bash
  docker run -p 6688:6688 -v PROJECT_PATH/.chainlink-kovan:/chainlink -it --env-file=.env smartcontract/chainlink local n -p /chainlink/.password -a /chainlink/.api
  ```

For running a Chainlink node on GCP follow the instruction in https://medium.com/secure-data-links/running-chainlink-nodes-on-kubernetes-and-the-google-cloud-platform-1fab922b3a1a

#### 2. Deploy an Chainlink Oracle

  - Follow the steps from [Chainlink Docs - Deploy your own Oracle contract](https://docs.chain.link/docs/fulfilling-requests#section-deploy-your-own-oracle-contract) and [Chainlink Docs - ](https://docs.chain.link/docs/fulfilling-requests#section-deploy-your-own-oracle-contract)

#### 3. Create Google Sheets Response Table

  - Organize your data in Google Sheets. Consolidate data to be returned to the oracle to facilitate queries. 
  Follow the steps from [Google Sheets API documentation](https://developers.google.com/sheets/api/quickstart/nodejs) to enable API access to your spreadsheet. Be sure to note the URL to your spreadsheet (it includes the spreadsheet ID) 

#### 4. Deploy External Adapter function

  - Follow the steps from https://chainlinkadapters.com/guides/run-external-adapter-on-gcp for deploying the `external-adapter` as a Cloud Function in GCP.

    **Note:** If token expires, be sure to run adapter code locally and redeploy adapter with refreshed token.

#### 5. Create bridge for the External Adapter

  Reference docs: https://docs.chain.link/docs/node-operators

  External adapters are added to the Chainlink node by creating a bridge type. Bridges define the tasks' name and URL of the external adapter. When a task type is received, and it is not one of the core adapters, the node will search for a bridge type with that name, utilizing the bridge to your external adapter.

  **Note:** Bridge and task type names are case insensitive.

  To create a bridge on the node, you can navigate to the "Create Bridge" menu item in the GUI. From there, you will specify a Name, URL and, optionally, the number of Confirmations for the bridge.

  **Note:** Bridge Name should be unique to the local node and the Bridge URL should be the URL of your external adapter, whether local or on a separate machine.

#### 6. Create job which uses the bridge

Create a job in the node like the following one

```javascript
  {
    "initiators": [
      { "type": "runLog" }
    ],
    "tasks": [
      { "type": "BRIDGE NAME FROM STEP 4" },
      { "type": "ethuint256" },
      { "type": "ethtx" }
    ]
  }
```

#### 7. Deploy InvoiceRate contract
Within the `oracle` directory:

```bash
npm i
```

Create a `.env` file, copy content of `.env.example` and update `RPC_URL` with your Infura PROJECT_ID, `PK` with your account private key, `ORACLE` with the address of the contract deployed on step #2 and `JOB_ID` with what you got from step #5.

```bash
npm run migrate:kovan
```

Fund `InvoiceContract` using `https://kovan.chain.link/`

#### 8. Execute oracle method

```bash
eth abi:add InvoiceRate PATH_TO_BUILD_FOLDER/contracts/InvoiceRate.json
eth contract:send --kovan InvoiceRate@INVOCE_PRICE_CONTRACT_ADDRESS 'requestInvoiceRate("182")' --pk=YOUR_ADDRESS_PK
```
The contract can also be executed via Etherscan platform (https://kovan.etherscan.io/address/<INVOCE_PRICE_CONTRACT_ADDRESS>) under Contract >> Write Contract

#### 9. Check out the results

`InvoiceRate` contract emits the event `LtvRatio(bytes32 indexed requestId, uint256 timestamp, uint256 price)` when the request to the External Adapter is fulfilled so go to https://kovan.etherscan.io/address/INVOCE_PRICE_CONTRACT_ADDRESS#events and check the event was emmited.

.