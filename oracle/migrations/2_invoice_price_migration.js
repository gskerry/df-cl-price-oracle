require('dotenv').config()
const InvoicePrice = artifacts.require('InvoicePrice')

module.exports = (deployer, network) => {
  deployer.deploy(InvoicePrice, process.env.ORACLE, process.env.JOB_ID)
}
