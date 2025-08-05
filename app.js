const express = require('express')
const app = express()
const port = process.env.PORT || 3000

app.get('/', (req, res) => res.send('<h3>Node CI-CD *******************</h3>'))

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() })
})

app.listen(port, '0.0.0.0', () => console.log(`Example app listening on port ${port}!!`))
