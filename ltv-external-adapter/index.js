const api = require('./sheet_api.js')
const utils = require('./utils')

exports.execute = async function (req, res){
  let scoredat = req.body && req.body.data && req.body.data.score || 0
  let tier = scoredat > 90 ? 3
    : scoredat > 80 ? 4
    : scoredat > 70 ? 5
    : 6
  try {
    let payload = await api.getRate(tier);
    const data = {
      jobRunID: req.body.id,
      data: utils.pack(64, payload.values[0].map(val => val !== 'n/a' ? val*10000 : 0)),
      statusCode: 200
    }

    res.status(200).send(data)
  } catch {
    const data = {
      jobRunID: req.body.id,
      data: {},
      statusCode: 500,
      error: "ERROR"
    }

    res.status(500).send(data)
  }
}
