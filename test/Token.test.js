// const {
//   TOKEN_NAME,
//   TOKEN_SYMBOL
// } = require('./helpers');

const Token = artifacts.require('./contracts/Token.sol')

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('Token', ([owner]) => {
  let token
  
  beforeEach(async () => {
    token = await Token.new("AndrewCoin", "AML", { from: owner })
  })
  
  describe('deployment', async () => {
    it('deploys successfully', async () => {
      const address = await token.address
      address.should.not.equal(0x0, 'address does not equal 0x0')
      address.should.not.equal('', 'address does not equal ""')
      address.should.not.equal(null, 'address does not equal null')
      address.should.not.equal(undefined, 'address does not equal undefined')
    })

    it('tracks token name', async () => {
      const name = await token.name()
      name.toString().should.equal("AndrewCoin")
    })

    it('tracks token symbol', async () => {
      const symbol = await token.symbol()
      symbol.toString().should.equal("AML")
    })

    it('tracks initial mint', async () => {
      const balance = await token.balanceOf(owner)
      balance.toString().should.equal("1000000000000000000000000000")
    })
  })
})