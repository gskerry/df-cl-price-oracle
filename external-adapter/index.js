exports.invocePrice = (req, res) => {
  const days = req.body && req.body.data && req.body.data.days || 0

  const data = {
    jobRunID: req.body.id,
    data: getRatio(days),
    statusCode: 200
  }

  res.status(200).send(data)
}

function getRatio(days) {
  const ratio = days < 6 ? 100
    : days < 31 ? 96
    : days < 91 ? 92
    : days < 181 ? 88
    : 82

  return ratio
}
