require('dotenv').config()
const LtvRatio = artifacts.require('LtvRatio')

module.exports = (deployer, network) => {
  deployer.deploy(LtvRatio, process.env.ORACLE, process.env.JOB_ID)
}
